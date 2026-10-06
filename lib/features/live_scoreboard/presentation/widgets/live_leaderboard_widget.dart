import 'package:flutter/material.dart';

import '../../../../core/widgets/liquid_glass_card.dart';
import '../../domain/entities/driver_standing.dart';

class LiveLeaderboardWidget extends StatelessWidget {
  final List<DriverStanding> standings;

  const LiveLeaderboardWidget({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return const LiquidGlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(
            child: Text(
              'No position data has been published for this session yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB8C0CC), height: 1.5),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final driver in standings) ...[
          _DriverRow(driver: driver),
          if (driver != standings.last) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _DriverRow extends StatelessWidget {
  final DriverStanding driver;

  const _DriverRow({required this.driver});

  @override
  Widget build(BuildContext context) {
    final teamColor = _teamColor(driver.teamColour);
    final isLeader = driver.position == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xC8161D28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              driver.position.toString().padLeft(2, '0'),
              style: TextStyle(
                color: isLeader ? const Color(0xFFFF5A52) : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${driver.driverCode.toUpperCase()}  ·  ${driver.teamName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFABB4C2),
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            driver.gapOrTime,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isLeader ? const Color(0xFFFF6A62) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Color _teamColor(String value) {
    final normalized = value.replaceAll('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null
        ? const Color(0xFF87909A)
        : Color(0xFF000000 | parsed);
  }
}
