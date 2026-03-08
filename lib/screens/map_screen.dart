import 'package:flutter/material.dart';

import '../shared/nav_speed_dial.dart';
import '../shared/theme.dart';
import 'pin_list_screen.dart';
import 'settings_screen.dart';

/// Placeholder 2D Map screen (WOE-066).
///
/// Shows centered title and NAV FAB with Map highlighted.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      backgroundColor: tokens.surfacePrimary,
      body: Stack(
        children: [
          Center(
            child: Text(
              '2D Map',
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
              activeDestination: NavDestination.map,
              onPinsTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => const PinListScreen()),
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
