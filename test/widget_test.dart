import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:f1_scoreboard_app/features/live_scoreboard/data/openf1_service.dart';
import 'package:f1_scoreboard_app/features/live_scoreboard/domain/entities/driver_standing.dart';

void main() {
  test('builds latest driver order and gaps from OpenF1 records', () {
    final standings = OpenF1Service.buildStandings(
      drivers: _drivers,
      positions: [
        {'driver_number': 1, 'position': 1, 'date': '2026-10-04T07:00:00Z'},
        {'driver_number': 1, 'position': 2, 'date': '2026-10-04T07:00:05Z'},
        {'driver_number': 4, 'position': 1, 'date': '2026-10-04T07:00:05Z'},
      ],
      intervals: [
        {
          'driver_number': 1,
          'gap_to_leader': 1.25,
          'date': '2026-10-04T07:00:05Z',
        },
      ],
    );

    expect(standings.map((driver) => driver.driverCode), ['NOR', 'VER']);
    expect(standings.first.gapOrTime, 'LEADER');
    expect(standings.last.gapOrTime, '+1.250s');
    expect(standings.last.teamColour, '3671C6');
  });

  test('orders practice and qualifying by each driver’s best valid lap', () {
    final standings = OpenF1Service.buildStandings(
      drivers: _drivers,
      positions: const [],
      intervals: const [],
      laps: [
        _lap(1, 92.5),
        _lap(1, 91.234),
        {..._lap(1, 80.0), 'is_pit_out_lap': true},
        _lap(4, 91.456),
      ],
    );

    expect(standings.map((driver) => driver.driverCode), ['VER', 'NOR']);
    expect(standings.map((driver) => driver.position), [1, 2]);
    expect(standings.map((driver) => driver.gapOrTime), [
      '1:31.234',
      '1:31.456',
    ]);
  });

  test(
    'fetches practice and qualifying laps without requiring intervals',
    () async {
      final now = DateTime.now().toUtc();
      final lastWeek = now.subtract(const Duration(days: 7));
      final schedule = [
        _session(10, 'Practice 1', lastWeek),
        _session(11, 'Practice 3', lastWeek.add(const Duration(days: 1))),
        _session(12, 'Qualifying', lastWeek.add(const Duration(days: 2))),
        _session(13, 'Race', lastWeek.add(const Duration(days: 3))),
      ];
      final futureMeeting = now.add(const Duration(days: 20));
      final requestLog = <String>[];
      final client = MockClient((request) async {
        requestLog.add(request.url.toString());
        final path = request.url.path;
        if (path.endsWith('/sessions') &&
            request.url.queryParameters.containsKey('session_key')) {
          return _jsonResponse([
            {...schedule.last, 'year': now.year},
          ]);
        }
        if (path.endsWith('/sessions')) return _jsonResponse(schedule);
        if (path.endsWith('/meetings')) {
          return _jsonResponse([
            {
              'meeting_name': 'Future Grand Prix',
              'location': 'Austin',
              'country_name': 'United States',
              'date_start': futureMeeting.toIso8601String(),
              'is_cancelled': false,
            },
          ]);
        }
        if (path.endsWith('/drivers')) return _jsonResponse(_drivers);
        if (path.endsWith('/position') || path.endsWith('/intervals')) {
          return http.Response('Not found', 404);
        }
        if (path.endsWith('/laps')) {
          final sessionKey = request.url.queryParameters['session_key'];
          return _jsonResponse(
            sessionKey == '11'
                ? [_lap(1, 92.5), _lap(1, 91.234), _lap(4, 91.456)]
                : [_lap(1, 90.8), _lap(4, 90.2)],
          );
        }
        return http.Response('Unexpected endpoint', 500);
      });
      final service = OpenF1Service(
        client: client,
        baseUrl: 'https://test.api',
      );
      addTearDown(service.close);

      final practice = await service.fetchTimingSnapshot(SessionType.practice);
      final qualifying = await service.fetchTimingSnapshot(
        SessionType.qualifying,
      );

      expect(practice.sessionName, 'Practice 3');
      expect(practice.sessionKey, '11');
      expect(practice.drivers.map((driver) => driver.driverCode), [
        'VER',
        'NOR',
      ]);
      expect(practice.drivers.map((driver) => driver.gapOrTime), [
        '1:31.234',
        '1:31.456',
      ]);
      expect(qualifying.sessionName, 'Qualifying');
      expect(qualifying.sessionKey, '12');
      expect(qualifying.drivers.map((driver) => driver.driverCode), [
        'NOR',
        'VER',
      ]);
      expect(qualifying.nextGrandPrixName, 'Future Grand Prix');
      expect(qualifying.nextGrandPrixLocation, 'Austin');
      expect(requestLog.where((url) => url.contains('/intervals?')).length, 2);
    },
  );
}

http.Response _jsonResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _session(int key, String name, DateTime date) => {
  'session_key': key,
  'session_name': name,
  'session_type': name,
  'date_start': date.toIso8601String(),
  'date_end': date.add(const Duration(hours: 1)).toIso8601String(),
  'meeting_key': 100,
  'circuit_short_name': 'Example Circuit',
  'location': 'Example City',
  'country_name': 'Example Country',
};

Map<String, dynamic> _lap(int driverNumber, double seconds) => {
  'driver_number': driverNumber,
  'lap_duration': seconds,
  'is_pit_out_lap': false,
};

const _drivers = [
  {
    'driver_number': 1,
    'name_acronym': 'VER',
    'full_name': 'Max Verstappen',
    'team_name': 'Red Bull Racing',
    'team_colour': '3671C6',
  },
  {
    'driver_number': 4,
    'name_acronym': 'NOR',
    'full_name': 'Lando Norris',
    'team_name': 'McLaren',
    'team_colour': 'FF8000',
  },
];
