import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../position/position_controller.dart';
import '../position/position_source.dart';
import 'theme.dart';

/// Compact semi-transparent pill bar pinned to the top of the AR View and
/// 2D Map View. Always visible, not interactive in V1.
///
/// Displays: position source dot + label, data age, connectivity icon,
/// and tile cache freshness warning.
///
/// Reference: UI_SPEC SS5.1, supersedes WOE-015
class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({
    super.key,
    this.lastTileSync,
  });

  /// When set, shows a "Stale" warning if older than 30 days.
  final DateTime? lastTileSync;

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  Timer? _ageTimer;
  int _ageSeconds = -1;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _ageTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateAge());
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

  static bool _hasInternet(List<ConnectivityResult> results) => results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);

  void _updateAge() {
    final status = ref.read(positionControllerProvider).value;
    final lastFix = status?.lastFixAt;
    if (lastFix == null) {
      if (_ageSeconds != -1) setState(() => _ageSeconds = -1);
      return;
    }
    final seconds = DateTime.now().toUtc().difference(lastFix).inSeconds;
    if (seconds != _ageSeconds) setState(() => _ageSeconds = seconds);
  }

  @override
  void dispose() {
    _ageTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  bool get _isTileStale {
    final sync = widget.lastTileSync;
    if (sync == null) return false;
    return DateTime.now().toUtc().difference(sync).inDays > 30;
  }

  @override
  Widget build(BuildContext context) {
    final asyncStatus = ref.watch(positionControllerProvider);
    final status = asyncStatus.value;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final fontSize = tokens.hudFontSize - 1;
    final textStyle = TextStyle(
      fontFamily: tokens.hudFontFamily,
      fontSize: fontSize,
      color: tokens.hudPrimary,
    );

    final sourceType = status?.sourceType;
    final sourceLabel = _sourceLabel(sourceType);
    final sourceColor = _sourceColor(sourceType, tokens);

    final showAge = sourceType != PositionSourceType.static && _ageSeconds >= 1;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source dot
          _Dot(color: sourceColor),
          const SizedBox(width: 4),
          // Source label
          Text(sourceLabel, style: textStyle.copyWith(color: sourceColor)),
          // Age
          if (showAge) ...[
            _separator(textStyle),
            Text(_formatAge(_ageSeconds), style: textStyle),
          ],
          // Connectivity icon
          _separator(textStyle),
          Icon(
            _isOnline ? Icons.wifi : Icons.warning_amber_rounded,
            size: fontSize + 3,
            color: _isOnline ? tokens.hudPrimary : tokens.statusOffline,
          ),
          // Tile freshness warning
          if (_isTileStale) ...[
            _separator(textStyle),
            Icon(Icons.map, size: fontSize + 3, color: tokens.hudWarning),
            const SizedBox(width: 2),
            Text('Stale',
                style: textStyle.copyWith(color: tokens.hudWarning)),
          ],
        ],
      ),
    );
  }

  Widget _separator(TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('\u00B7', style: style),
      );

  static String _sourceLabel(PositionSourceType? type) => switch (type) {
        PositionSourceType.live => 'ISS Live',
        PositionSourceType.estimated => 'TLE Estimated',
        PositionSourceType.gps => 'GPS',
        PositionSourceType.static => 'Static',
        null => 'Connecting\u2026',
      };

  static Color _sourceColor(PositionSourceType? type, AppTokens tokens) =>
      switch (type) {
        PositionSourceType.live => tokens.statusLive,
        PositionSourceType.estimated => tokens.statusEstimated,
        PositionSourceType.gps => tokens.statusLive,
        PositionSourceType.static => tokens.statusOffline,
        null => tokens.statusOffline,
      };

  static String _formatAge(int seconds) {
    if (seconds < 60) return '${seconds}s ago';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m ago';
    return '${minutes ~/ 60}h ago';
  }
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
