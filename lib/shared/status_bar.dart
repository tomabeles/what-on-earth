import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../position/position_controller.dart';
import '../position/position_source.dart';
import 'theme.dart';

/// Persistent status bar showing the current position source, data freshness,
/// and network connectivity.
///
/// Displays on all primary screens (AR view, 2D map). Fits within a 40 dp
/// strip and meets WCAG 2.1 AA contrast on the dark globe background.
///
/// Reference: TECH_SPEC §10.3, PRD FR-POS-005
class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  Timer? _ageTimer;
  String _ageLabel = '';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateAge());
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) setState(() => _isOnline = _hasInternet(result));
    } catch (_) {
      // Fallback: assume online if check fails.
    }
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) setState(() => _isOnline = _hasInternet(result));
    });
  }

  static bool _hasInternet(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);

  void _updateAge() {
    final status = ref.read(positionControllerProvider).value;
    final lastFix = status?.lastFixAt;
    if (lastFix == null) {
      if (_ageLabel != '') setState(() => _ageLabel = '');
      return;
    }
    final seconds = DateTime.now().toUtc().difference(lastFix).inSeconds;
    final label = _formatAge(seconds);
    if (label != _ageLabel) setState(() => _ageLabel = label);
  }

  static String _formatAge(int seconds) {
    if (seconds < 1) return 'Updated just now';
    if (seconds < 60) return 'Updated ${seconds}s ago';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return 'Updated ${minutes}m ago';
    return 'Updated ${minutes ~/ 60}h ago';
  }

  @override
  void dispose() {
    _ageTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncStatus = ref.watch(positionControllerProvider);
    final status = asyncStatus.value;
    final tokens = Theme.of(context).extension<AppTokens>();

    final sourceLabel = _sourceLabel(status?.sourceType);
    final sourceColor = _sourceColor(status?.sourceType, tokens);
    final connectColor = _isOnline
        ? (tokens?.statusLive ?? const Color(0xFF34C759))
        : (tokens?.statusOffline ?? const Color(0xFF8E8E93));

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens?.hudBackground ?? const Color(0x99000000),
      ),
      child: Row(
        children: [
          // Source indicator dot + label.
          _Dot(color: sourceColor),
          const SizedBox(width: 6),
          Text(
            sourceLabel,
            style: TextStyle(
              color: sourceColor,
              fontSize: tokens?.hudFontSize ?? 11,
              fontFamily: tokens?.hudFontFamily ?? 'JetBrainsMono',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          // Age label.
          if (_ageLabel.isNotEmpty)
            Expanded(
              child: Text(
                _ageLabel,
                style: TextStyle(
                  color: tokens?.hudSecondary ?? const Color(0xFF8BB8C8),
                  fontSize: tokens?.hudFontSize ?? 11,
                  fontFamily: tokens?.hudFontFamily ?? 'JetBrainsMono',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          // Connectivity dot.
          _Dot(color: connectColor),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: connectColor,
              fontSize: tokens?.hudFontSize ?? 11,
              fontFamily: tokens?.hudFontFamily ?? 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  static String _sourceLabel(PositionSourceType? type) => switch (type) {
        PositionSourceType.live => 'ISS Live',
        PositionSourceType.estimated => 'Estimated (TLE)',
        PositionSourceType.static => 'Static',
        null => 'Connecting…',
      };

  static Color _sourceColor(PositionSourceType? type, AppTokens? tokens) =>
      switch (type) {
        PositionSourceType.live =>
          tokens?.statusLive ?? const Color(0xFF34C759),
        PositionSourceType.estimated =>
          tokens?.statusEstimated ?? const Color(0xFFFFB340),
        PositionSourceType.static =>
          tokens?.statusOffline ?? const Color(0xFF8E8E93),
        null => tokens?.statusOffline ?? const Color(0xFF8E8E93),
      };
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
