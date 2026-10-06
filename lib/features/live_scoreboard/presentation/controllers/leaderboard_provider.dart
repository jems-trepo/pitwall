import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../data/openf1_service.dart';
import '../../domain/entities/driver_standing.dart';
import '../../domain/entities/timing_snapshot.dart';

final openF1ServiceProvider = Provider<OpenF1Service>((ref) {
  final service = OpenF1Service();
  ref.onDispose(service.close);
  return service;
});

final sessionFilterProvider =
    NotifierProvider<SessionFilterNotifier, SessionType>(
      SessionFilterNotifier.new,
    );

class SessionFilterNotifier extends Notifier<SessionType> {
  @override
  SessionType build() => SessionType.race;

  void selectSession(SessionType session) => state = session;
}

final liveTimingProvider = FutureProvider.autoDispose
    .family<TimingSnapshot, SessionType>((ref, sessionType) {
      final service = ref.watch(openF1ServiceProvider);
      Timer? refreshTimer;
      var disposed = false;
      ref.onDispose(() {
        disposed = true;
        refreshTimer?.cancel();
      });

      Future<TimingSnapshot> loadSnapshot() async {
        var refreshDelay = const Duration(minutes: 1);
        try {
          final snapshot = await service.fetchTimingSnapshot(sessionType);
          refreshDelay = snapshot.isLive
              ? const Duration(seconds: 10)
              : const Duration(minutes: 1);
          return snapshot;
        } finally {
          refreshTimer = Timer(refreshDelay, () {
            if (!disposed) ref.invalidateSelf();
          });
        }
      }

      return loadSnapshot();
    });
