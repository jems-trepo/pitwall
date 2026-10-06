enum SessionType { practice, qualifying, race }

class DriverStanding {
  final int position;
  final int driverNumber;
  final String driverCode;
  final String driverName;
  final String teamName;
  final String teamColour;
  final String gapOrTime;

  const DriverStanding({
    required this.position,
    required this.driverNumber,
    required this.driverCode,
    required this.driverName,
    required this.teamName,
    required this.gapOrTime,
    required this.teamColour,
  });
}
