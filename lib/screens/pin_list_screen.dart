import 'package:flutter/material.dart';

import '../shared/nav_speed_dial.dart';
import '../shared/theme.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

/// Placeholder Pin List screen (WOE-066).
///
/// Shows centered title and NAV FAB with Pins highlighted.
class PinListScreen extends StatelessWidget {
  const PinListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      backgroundColor: tokens.surfacePrimary,
      body: Stack(
        children: [
          Center(
            child: Text(
              'Pins',
              style: TextStyle(
                color: tokens.hudPrimary,
                fontSize: 24,
                fontFamily: tokens.hudFontFamily,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: NavSpeedDial(
              activeDestination: NavDestination.pins,
              onMapTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => const MapScreen()),
              ),
              onSettingsTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
