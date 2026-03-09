import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/nav_speed_dial.dart';
import '../shared/settings_content.dart';
import '../shared/theme.dart';

/// Settings screen — grouped list (UI_SPEC §4.6).
///
/// Contains: Display section (WOE-080), Position Source section (WOE-081).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      backgroundColor: tokens.surfacePrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: tokens.surfacePrimary,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              DisplaySection(),
              SizedBox(height: 16),
              PositionSourceSection(),
            ],
          ),
          // NAV FAB with Settings highlighted
          Positioned(
            right: 16,
            bottom: 16,
            child: NavSpeedDial(
              activeDestination: NavDestination.settings,
              onMapTap: () => Navigator.of(context).pop(),
              onPinsTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
