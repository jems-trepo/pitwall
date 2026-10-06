import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/driver_standing.dart';
import '../domain/entities/timing_snapshot.dart';

class OpenF1Service {
  static const _defaultBaseUrl = 'https://api.openf1.org/v1';
  static const _requestTimeout = Duration(seconds: 30);
  static const _cacheDuration = Duration(minutes: 10);
  static const _minimumRequestSpacing = Duration(milliseconds: 450);

  final http.Client _client;
  final String _baseUrl;

  OpenF1Service({http.Client? client, this._baseUrl = _defaultBaseUrl})
    : _client = client ?? http.Client();

  List<Map<String, dynamic>>? _cachedSchedule;
  String? _cachedMeetingKey;
  DateTime? _scheduleCachedAt;
  List<Map<String, dynamic>>? _cachedMeetings;
  int? _cachedMeetingsYear;
  DateTime? _meetingsCachedAt;
  DateTime? _lastRequestStartedAt;
  final _driversBySession = <String, List<Map<String, dynamic>>>{};
  final _intervalsBySession = <String, List<Map<String, dynamic>>>{};
  final _lapsBySession = <String, List<Map<String, dynamic>>>{};

  Future<TimingSnapshot> fetchTimingSnapshot(SessionType sessionType) async {
    final latestSessions = await _getRecords('/sessions', {
      'session_key': 'latest',
    });
    if (latestSessions.isEmpty) {
      throw const OpenF1Exception('OpenF1 has no session data available yet.');
    }

    final latestSession = latestSessions.last;
    final meetingKeyString = latestSession['meeting_key']?.toString();
    final year = _integer(latestSession['year']) ?? DateTime.now().year;
    final meetings = await _getMeetings(year);
    final nextMeeting = _nextMeeting(meetings);
    final schedule = await _getMeetingSchedule(meetingKeyString, latestSession);
    final session = _selectSession(schedule, latestSession, sessionType);
    final sessionKey = session['session_key'];
    if (sessionKey == null) {
      throw const OpenF1Exception('OpenF1 did not provide a session key.');
    }

    final sessionKeyString = '$sessionKey';
    final query = {'session_key': sessionKeyString};
    final sessionStart = DateTime.tryParse(
      _string(session['date_start']) ?? '',
    );
    final sessionEnd = DateTime.tryParse(_string(session['date_end']) ?? '');
    final now = DateTime.now().toUtc();
    final isLive =
        sessionStart != null &&
        sessionEnd != null &&
        !now.isBefore(sessionStart.toUtc()) &&
        !now.isAfter(sessionEnd.toUtc());

    var drivers = _driversBySession[sessionKeyString];
    if (drivers == null) {
      drivers = await _getRecords('/drivers', query);
      _driversBySession[sessionKeyString] = drivers;
    }
    final positions = await _getOptionalRecords('/position', query);

    var intervals = _intervalsBySession[sessionKeyString];
    if (isLive || intervals == null) {
      final intervalsQuery = isLive
          ? {
              ...query,
              'date>=': now
                  .subtract(const Duration(seconds: 15))
                  .toIso8601String(),
            }
          : query;
      intervals = await _getOptionalRecords('/intervals', intervalsQuery);
      if (!isLive) _intervalsBySession[sessionKeyString] = intervals;
    }

    var laps = _lapsBySession[sessionKeyString];
    if (sessionType != SessionType.race && laps == null) {
      laps = await _getOptionalRecords('/laps', query);
      _lapsBySession[sessionKeyString] = laps;
    }

    return TimingSnapshot(
      sessionName:
          _string(session['session_name']) ??
          _string(session['session_type']) ??
          'F1 Session',
      circuitName:
          _string(session['circuit_short_name']) ??
          _string(latestSession['circuit_short_name']) ??
          'Circuit',
      location:
          _string(session['location']) ??
          _string(latestSession['location']) ??
          '',
      countryName:
          _string(session['country_name']) ??
          _string(latestSession['country_name']) ??
          '',
      sessionKey: sessionKeyString,
      nextGrandPrixName: _string(nextMeeting?['meeting_name']),
      nextGrandPrixLocation: _string(nextMeeting?['location']),
      nextGrandPrixCountry: _string(nextMeeting?['country_name']),
      nextGrandPrixDate: DateTime.tryParse(
        _string(nextMeeting?['date_start']) ?? '',
      ),
      dateStart: sessionStart,
      dateEnd: sessionEnd,
      drivers: buildStandings(
        drivers: drivers,
        positions: positions,
        intervals: intervals,
        laps: laps ?? const [],
      ),
      updatedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> _getMeetingSchedule(
    String? meetingKey,
    Map<String, dynamic> latestSession,
  ) async {
    if (meetingKey == null) return [latestSession];
    final cacheAge = _scheduleCachedAt == null
        ? null
        : DateTime.now().difference(_scheduleCachedAt!);
    if (_cachedSchedule != null &&
        _cachedMeetingKey == meetingKey &&
        cacheAge != null &&
        cacheAge < _cacheDuration) {
      return _cachedSchedule!;
    }

    final schedule = await _getRecords('/sessions', {
      'meeting_key': meetingKey,
    });
    _cachedSchedule = schedule;
    _cachedMeetingKey = meetingKey;
    _scheduleCachedAt = DateTime.now();
    return schedule;
  }

  Future<List<Map<String, dynamic>>> _getMeetings(int year) async {
    final cacheAge = _meetingsCachedAt == null
        ? null
        : DateTime.now().difference(_meetingsCachedAt!);
    if (_cachedMeetings != null &&
        _cachedMeetingsYear == year &&
        cacheAge != null &&
        cacheAge < _cacheDuration) {
      return _cachedMeetings!;
    }

    final meetings = await _getRecords('/meetings', {'year': '$year'});
    _cachedMeetings = meetings;
    _cachedMeetingsYear = year;
    _meetingsCachedAt = DateTime.now();
    return meetings;
  }

  static Map<String, dynamic>? _nextMeeting(
    List<Map<String, dynamic>> meetings,
  ) {
    final now = DateTime.now().toUtc();
    final upcoming =
        meetings.where((meeting) {
          if (meeting['is_cancelled'] == true) return false;
          final start = DateTime.tryParse(_string(meeting['date_start']) ?? '');
          return start != null && start.toUtc().isAfter(now);
        }).toList()..sort((a, b) {
          final aStart = DateTime.parse(_string(a['date_start'])!);
          final bStart = DateTime.parse(_string(b['date_start'])!);
          return aStart.compareTo(bStart);
        });
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<List<Map<String, dynamic>>> _getOptionalRecords(
    String path,
    Map<String, String> query,
  ) async {
    try {
      return await _getRecords(path, query);
    } on OpenF1Exception catch (error) {
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getRecords(
    String path,
    Map<String, String> query,
  ) async {
    final lastRequest = _lastRequestStartedAt;
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      final remaining = _minimumRequestSpacing - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    _lastRequestStartedAt = DateTime.now();

    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        throw const OpenF1Exception(
          'OpenF1 is rate limiting requests. Retrying shortly.',
          statusCode: 429,
        );
      }
      throw OpenF1Exception(
        'OpenF1 returned HTTP ${response.statusCode} for $path.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw OpenF1Exception('OpenF1 returned an invalid response for $path.');
    }
    return decoded
        .whereType<Map>()
        .map((record) => Map<String, dynamic>.from(record))
        .toList();
  }

  static List<DriverStanding> buildStandings({
    required List<Map<String, dynamic>> drivers,
    required List<Map<String, dynamic>> positions,
    required List<Map<String, dynamic>> intervals,
    List<Map<String, dynamic>> laps = const [],
  }) {
    final driverByNumber = <int, Map<String, dynamic>>{};
    for (final driver in drivers) {
      final number = _integer(driver['driver_number']);
      if (number != null) driverByNumber[number] = driver;
    }

    final bestLapTimes = _bestLapTimes(laps);
    if (bestLapTimes.isNotEmpty) {
      final lapOrder = bestLapTimes.entries.toList()
        ..sort((left, right) => left.value.compareTo(right.value));
      final standings = <DriverStanding>[];
      for (final entry in lapOrder) {
        final driver = driverByNumber[entry.key];
        if (driver == null) continue;
        standings.add(
          _standingForDriver(
            driver: driver,
            driverNumber: entry.key,
            position: standings.length + 1,
            gapOrTime: _formatLapTime(entry.value),
          ),
        );
      }
      if (standings.isNotEmpty) return standings;
    }

    final latestPositions = _latestByDriver(positions);
    final latestIntervals = _latestByDriver(intervals);
    final standings = <DriverStanding>[];

    for (final entry in latestPositions.entries) {
      final position = _integer(entry.value['position']);
      final driver = driverByNumber[entry.key];
      if (position == null || driver == null) continue;

      final interval = latestIntervals[entry.key];
      standings.add(
        _standingForDriver(
          driver: driver,
          driverNumber: entry.key,
          position: position,
          gapOrTime: position == 1
              ? 'LEADER'
              : _formatInterval(
                  interval?['gap_to_leader'] ?? interval?['interval'],
                ),
        ),
      );
    }

    standings.sort((left, right) => left.position.compareTo(right.position));
    return standings;
  }

  static DriverStanding _standingForDriver({
    required Map<String, dynamic> driver,
    required int driverNumber,
    required int position,
    required String gapOrTime,
  }) {
    final givenName = _string(driver['first_name']) ?? '';
    final familyName = _string(driver['last_name']) ?? '';
    final fullName =
        _string(driver['full_name']) ??
        [givenName, familyName].where((part) => part.isNotEmpty).join(' ');
    return DriverStanding(
      position: position,
      driverNumber: driverNumber,
      driverCode:
          _string(driver['name_acronym']) ??
          _string(driver['broadcast_name']) ??
          '$driverNumber',
      driverName: fullName.isEmpty ? 'Driver $driverNumber' : fullName,
      teamName: _string(driver['team_name']) ?? 'Unknown team',
      teamColour: _string(driver['team_colour']) ?? '87909A',
      gapOrTime: gapOrTime,
    );
  }

  static Map<int, double> _bestLapTimes(List<Map<String, dynamic>> laps) {
    final bestByDriver = <int, double>{};
    for (final lap in laps) {
      if (lap['is_pit_out_lap'] == true) continue;
      final driverNumber = _integer(lap['driver_number']);
      final duration = double.tryParse(lap['lap_duration']?.toString() ?? '');
      if (driverNumber == null || duration == null || duration <= 0) continue;
      final currentBest = bestByDriver[driverNumber];
      if (currentBest == null || duration < currentBest) {
        bestByDriver[driverNumber] = duration;
      }
    }
    return bestByDriver;
  }

  static String _formatLapTime(double seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds - minutes * 60;
    return '$minutes:${remainingSeconds.toStringAsFixed(3).padLeft(6, '0')}';
  }

  static Map<int, Map<String, dynamic>> _latestByDriver(
    List<Map<String, dynamic>> records,
  ) {
    final latest = <int, Map<String, dynamic>>{};
    for (final record in records) {
      final number = _integer(record['driver_number']);
      if (number == null) continue;
      final current = latest[number];
      final currentDate = DateTime.tryParse(_string(current?['date']) ?? '');
      final recordDate = DateTime.tryParse(_string(record['date']) ?? '');
      if (current == null ||
          (recordDate != null &&
              (currentDate == null || recordDate.isAfter(currentDate)))) {
        latest[number] = record;
      }
    }
    return latest;
  }

  static Map<String, dynamic> _selectSession(
    List<Map<String, dynamic>> schedule,
    Map<String, dynamic> latestSession,
    SessionType type,
  ) {
    final matches =
        schedule.where((session) {
          final name = (_string(session['session_name']) ?? '').toLowerCase();
          switch (type) {
            case SessionType.practice:
              return name.startsWith('practice');
            case SessionType.qualifying:
              return name.contains('qualifying');
            case SessionType.race:
              return name == 'race' || name == 'sprint';
          }
        }).toList()..sort((left, right) {
          final leftDate =
              DateTime.tryParse(_string(left['date_start']) ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final rightDate =
              DateTime.tryParse(_string(right['date_start']) ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return leftDate.compareTo(rightDate);
        });
    return matches.isEmpty ? latestSession : matches.last;
  }

  static String _formatInterval(dynamic value) {
    if (value == null) return '--';
    final raw = value is List && value.isNotEmpty ? value.first : value;
    final seconds = double.tryParse(raw.toString());
    if (seconds == null) return raw.toString();
    if (seconds == 0) return '—';
    return '+${seconds.toStringAsFixed(3)}s';
  }

  static int? _integer(dynamic value) => int.tryParse(value?.toString() ?? '');

  static String? _string(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  void close() => _client.close();
}

class OpenF1Exception implements Exception {
  final String message;
  final int? statusCode;

  const OpenF1Exception(this.message, {this.statusCode});

  @override
  String toString() => message;
}
