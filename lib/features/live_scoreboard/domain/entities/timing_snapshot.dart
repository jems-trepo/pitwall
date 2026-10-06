import 'driver_standing.dart';

class TimingSnapshot {
  final String sessionName;
  final String circuitName;
  final String location;
  final String countryName;
  final String sessionKey;
  final String? nextGrandPrixName;
  final String? nextGrandPrixLocation;
  final String? nextGrandPrixCountry;
  final DateTime? nextGrandPrixDate;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final List<DriverStanding> drivers;
  final DateTime updatedAt;

  const TimingSnapshot({
    required this.sessionName,
    required this.circuitName,
    required this.location,
    required this.countryName,
    required this.sessionKey,
    required this.nextGrandPrixName,
    required this.nextGrandPrixLocation,
    required this.nextGrandPrixCountry,
    required this.nextGrandPrixDate,
    required this.dateStart,
    required this.dateEnd,
    required this.drivers,
    required this.updatedAt,
  });

  bool get isLive {
    final start = dateStart;
    final end = dateEnd;
    if (start == null || end == null) return false;
    final now = DateTime.now().toUtc();
    return !now.isBefore(start.toUtc()) && !now.isAfter(end.toUtc());
  }
}
