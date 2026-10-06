import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/widgets/liquid_glass_card.dart';
import '../../domain/entities/driver_standing.dart';
import '../../domain/entities/timing_snapshot.dart';
import '../controllers/leaderboard_provider.dart';
import '../widgets/live_leaderboard_widget.dart';

class LiveScoreboardScreen extends ConsumerStatefulWidget {
  const LiveScoreboardScreen({super.key});

  @override
  ConsumerState<LiveScoreboardScreen> createState() =>
      _LiveScoreboardScreenState();
}

class _LiveScoreboardScreenState extends ConsumerState<LiveScoreboardScreen> {
  int _selectedTab = 0;
  bool _hasOpenedWatch = false;

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: const _AmbientBackground(),
      enableBackgroundSampling: false,
      statusBarStyle: GlassStatusBarStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedTab,
          children: [
            const _TimingDashboard(),
            if (_hasOpenedWatch)
              const _OfficialViewingPage()
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: _PitwallNavigationBar(
          selectedIndex: _selectedTab,
          onSelected: (index) => setState(() {
            _selectedTab = index;
            if (index == 1) _hasOpenedWatch = true;
          }),
        ),
      ),
    );
  }
}

class _TimingDashboard extends ConsumerWidget {
  const _TimingDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionType = ref.watch(sessionFilterProvider);
    final timing = ref.watch(liveTimingProvider(sessionType));
    final snapshot = timing.asData?.value;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              _Header(
                isLive: snapshot?.isLive ?? false,
                onRefresh: () =>
                    ref.invalidate(liveTimingProvider(sessionType)),
              ),
              const SizedBox(height: 24),
              _SessionPicker(
                selected: sessionType,
                onSelected: (value) => ref
                    .read(sessionFilterProvider.notifier)
                    .selectSession(value),
              ),
              const SizedBox(height: 16),
              if (snapshot != null) ...[
                _NextGrandPrixCard(snapshot: snapshot),
                const SizedBox(height: 14),
                _LeaderCard(snapshot: snapshot),
                const SizedBox(height: 14),
                _SessionMetaCard(snapshot: snapshot),
                const SizedBox(height: 25),
                _LeaderboardHeading(snapshot: snapshot),
                const SizedBox(height: 12),
                LiveLeaderboardWidget(standings: snapshot.drivers),
              ] else ...[
                timing.when(
                  loading: () => const _LoadingCard(),
                  error: (error, _) => _ErrorCard(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(liveTimingProvider(sessionType)),
                  ),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
              const SizedBox(height: 18),
              const _FooterNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PitwallNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PitwallNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xE8171D27),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                AnimatedAlign(
                  alignment: selectedIndex == 0
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: constraints.maxWidth / 2,
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6259), Color(0xFFD92D38)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5149)
                                  .withValues(alpha: 0.22),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _NavigationItem(
                      icon: Icons.speed_rounded,
                      label: 'Timing',
                      selected: selectedIndex == 0,
                      onTap: () => onSelected(0),
                    ),
                    _NavigationItem(
                      icon: Icons.live_tv_rounded,
                      label: 'Watch',
                      selected: selectedIndex == 1,
                      onTap: () => onSelected(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFF9EA8B7);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 21),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialViewingPage extends StatefulWidget {
  const _OfficialViewingPage();

  @override
  State<_OfficialViewingPage> createState() => _OfficialViewingPageState();
}

class _OfficialViewingPageState extends State<_OfficialViewingPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080B11))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _hasError = false;
                _progress = 0;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) {
              setState(() => _hasError = true);
            }
          },
          onNavigationRequest: (request) {
            return Uri.tryParse(request.url)?.scheme == 'https'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.formula1.com/en/subscribe-to-f1-tv'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WATCH RACING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Official F1 TV · opens inside Pitwall',
                        style: TextStyle(
                          color: Color(0xFFABB4C2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reload F1 TV',
                  onPressed: () => _controller.reload(),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100,
              minHeight: 2,
              color: const Color(0xFFFF5149),
              backgroundColor: Colors.white12,
            )
          else
            const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_hasError)
                      ColoredBox(
                        color: const Color(0xFF10151E),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Color(0xFFFF6259),
                                  size: 34,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'F1 TV could not be loaded',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Check your connection and try again. '
                                  'Viewing and playback depend on F1 TV '
                                  'availability in your region.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFABB4C2),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _controller.reload(),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111722), Color(0xFF080B11), Color(0xFF0D1119)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -150,
          left: -125,
          child: _GlowOrb(
            color: const Color(0xFFFF382E).withValues(alpha: 0.23),
            size: 340,
          ),
        ),
        Positioned(
          top: 330,
          right: -230,
          child: _GlowOrb(
            color: const Color(0xFF5667FF).withValues(alpha: 0.16),
            size: 420,
          ),
        ),
        Positioned(
          bottom: -220,
          left: 30,
          child: _GlowOrb(
            color: const Color(0xFF21D6B1).withValues(alpha: 0.10),
            size: 380,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isLive;
  final VoidCallback onRefresh;

  const _Header({required this.isLive, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFF433A),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF433A).withValues(alpha: 0.33),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Text(
            'F1',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PITWALL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'FORMULA 1 · LIVE TIMING',
                style: TextStyle(
                  color: Color(0xFFABB4C2),
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _LiveIndicator(isLive: isLive),
        const SizedBox(width: 5),
        IconButton(
          tooltip: 'Refresh timing',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
        ),
      ],
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  final bool isLive;

  const _LiveIndicator({required this.isLive});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? const Color(0xFFFF5149) : const Color(0xFF36D7A0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 7),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isLive ? 'LIVE' : 'TIMING',
            style: TextStyle(
              color: color,
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPicker extends StatelessWidget {
  final SessionType selected;
  final ValueChanged<SessionType> onSelected;

  const _SessionPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (final type in SessionType.values)
            Expanded(
              child: _SessionButton(
                type: type,
                selected: type == selected,
                onTap: () => onSelected(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  final SessionType type;
  final bool selected;
  final VoidCallback onTap;

  const _SessionButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      SessionType.practice => 'PRACTICE',
      SessionType.qualifying => 'QUALI',
      SessionType.race => 'RACE',
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF453D).withValues(alpha: 0.88)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF453D).withValues(alpha: 0.20),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFADB5C2),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class _NextGrandPrixCard extends StatelessWidget {
  final TimingSnapshot snapshot;

  const _NextGrandPrixCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final date = snapshot.nextGrandPrixDate?.toLocal();
    final location = [
      snapshot.nextGrandPrixLocation,
      snapshot.nextGrandPrixCountry,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
    final eventName = snapshot.nextGrandPrixName ?? 'Schedule unavailable';

    return LiquidGlassCard(
      borderRadius: 23,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5149).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF5149).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Color(0xFFFF655C),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT GRAND PRIX',
                  style: TextStyle(
                    color: Color(0xFFADB6C3),
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  eventName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBAC2CE),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (date != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMeetingDate(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _countdownLabel(date),
                  style: const TextStyle(
                    color: Color(0xFFFF766E),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatMeetingDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _countdownLabel(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days <= 0) return 'UP NEXT';
    return 'IN $days ${days == 1 ? 'DAY' : 'DAYS'}';
  }
}

class _LeaderCard extends StatelessWidget {
  final TimingSnapshot snapshot;

  const _LeaderCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final leader = snapshot.drivers.isEmpty ? null : snapshot.drivers.first;
    final secondPlace = snapshot.drivers.length < 2
        ? null
        : snapshot.drivers[1];
    final isLapSession =
        snapshot.sessionName.toLowerCase().contains('practice') ||
        snapshot.sessionName.toLowerCase().contains('qualifying');

    return LiquidGlassCard(
      borderRadius: 30,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                color: Color(0xFFFF6259),
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${snapshot.circuitName.toUpperCase()}${snapshot.countryName.isEmpty ? '' : '  ·  ${snapshot.countryName.toUpperCase()}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBBC3D0),
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.graphic_eq_rounded,
                size: 17,
                color: Color(0xFF7E8999),
              ),
            ],
          ),
          const SizedBox(height: 23),
          if (leader == null)
            const Text(
              'Waiting for positions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.position.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 0.95,
                    letterSpacing: -2,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SESSION LEADER',
                        style: TextStyle(
                          color: Color(0xFFABB4C2),
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        leader.driverName.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.06,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${leader.driverCode.toUpperCase()}  ·  ${leader.teamName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFBAC2CE),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 23),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: Color(0xFFABB4C2),
              ),
              const SizedBox(width: 7),
              Text(
                isLapSession ? 'BEST LAP' : 'GAP TO P2',
                style: const TextStyle(
                  color: Color(0xFFABB4C2),
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                isLapSession
                    ? leader?.gapOrTime ?? '--'
                    : secondPlace?.gapOrTime ?? '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionMetaCard extends StatelessWidget {
  final TimingSnapshot snapshot;

  const _SessionMetaCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final updated = TimeOfDay.fromDateTime(snapshot.updatedAt).format(context);
    final start = snapshot.dateStart;
    final dateText = start == null
        ? 'SESSION DATA'
        : '${start.toLocal().day.toString().padLeft(2, '0')}'
              '/${start.toLocal().month.toString().padLeft(2, '0')}'
              '/${start.toLocal().year}';

    return Row(
      children: [
        Expanded(
          child: _MetaTile(
            icon: Icons.flag_outlined,
            label: 'SESSION',
            value: snapshot.sessionName.toUpperCase(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaTile(
            icon: Icons.groups_2_outlined,
            label: 'CLASSIFIED',
            value: '${snapshot.drivers.length} DRIVERS',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaTile(
            icon: Icons.update_rounded,
            label: dateText,
            value: updated,
          ),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      borderRadius: 19,
      padding: const EdgeInsets.fromLTRB(11, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFFF655C)),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFADB6C3),
              fontSize: 8,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardHeading extends StatelessWidget {
  final TimingSnapshot snapshot;

  const _LeaderboardHeading({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLASSIFICATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Official timing order · refreshes automatically',
                style: TextStyle(color: Color(0xFFADB6C3), fontSize: 10),
              ),
            ],
          ),
        ),
        if (snapshot.isLive)
          const Text(
            '●  LIVE',
            style: TextStyle(
              color: Color(0xFFFF5B53),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const LiquidGlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF5149),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Connecting to OpenF1 timing…',
              style: TextStyle(color: Color(0xFFCED4DD), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIMING UNAVAILABLE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFB9C1CE),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('TRY AGAIN'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'DEVELOPED BY JEMS · UNOFFICIAL F1 TIMING',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF7E8999),
          fontSize: 8,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
