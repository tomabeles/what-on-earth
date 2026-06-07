import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug_provider.dart';
import 'layer_control_panel.dart' show SquareToggle;
import 'theme.dart';

/// Debug settings panel — toggled from the DBG> button in [HudCommandPanel].
class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final dbg = ref.watch(debugProvider);
    final notifier = ref.read(debugProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader('SENSORS', tokens),
          const SizedBox(height: 10),
          _toggle('ACCELEROMETER', dbg.accelerometerEnabled,
              notifier.toggleAccelerometer, tokens),
          const SizedBox(height: 8),
          _toggle('GYROSCOPE', dbg.gyroscopeEnabled,
              notifier.toggleGyroscope, tokens),
          const SizedBox(height: 8),
          _toggle('MAGNETOMETER', dbg.magnetometerEnabled,
              notifier.toggleMagnetometer, tokens),
          const SizedBox(height: 16),
          _sectionHeader('OVERLAYS', tokens),
          const SizedBox(height: 10),
          _toggle('COORD AXIS', dbg.showCoordAxis,
              notifier.toggleCoordAxis, tokens),
          const SizedBox(height: 8),
          _toggle('MAG REF', dbg.showMagRef,
              notifier.toggleMagRef, tokens),
          const SizedBox(height: 16),
          _sectionHeader('DIAGNOSTICS', tokens),
          const SizedBox(height: 10),
          _toggle('RAW VALUES', dbg.showRawValues,
              notifier.toggleRawValues, tokens),
          const SizedBox(height: 8),
          _toggle('FILTER STATS', dbg.showFilterStats,
              notifier.toggleFilterStats, tokens),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, AppTokens tokens) {
    return Text(
      label,
      style: TextStyle(
        color: tokens.hudPrimary,
        fontFamily: tokens.hudFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _toggle(
    String label,
    bool value,
    VoidCallback onChanged,
    AppTokens tokens,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: tokens.hudPrimary,
              fontFamily: tokens.hudFontFamily,
              fontSize: tokens.hudFontSize,
            ),
          ),
        ),
        SquareToggle(value: value, onChanged: onChanged, tokens: tokens),
      ],
    );
  }
}
