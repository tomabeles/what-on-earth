import 'package:flutter/material.dart';

import 'theme.dart';

/// Which screen the speed dial is currently showing on, used to highlight the
/// matching secondary FAB.
enum NavDestination { map, pins, settings }

/// Speed-dial floating action button — primary navigation control.
///
/// Pinned to bottom-right of AR View. Closed state: grid icon. Open state:
/// X icon with three secondary FABs animating upward.
///
/// Reference: UI_SPEC SS3.1, SS5.4
class NavSpeedDial extends StatefulWidget {
  const NavSpeedDial({
    super.key,
    this.activeDestination,
    this.onMapTap,
    this.onPinsTap,
    this.onSettingsTap,
  });

  /// Highlights the matching secondary FAB with `hudPrimary` background.
  final NavDestination? activeDestination;

  final VoidCallback? onMapTap;
  final VoidCallback? onPinsTap;
  final VoidCallback? onSettingsTap;

  @override
  State<NavSpeedDial> createState() => _NavSpeedDialState();
}

class _NavSpeedDialState extends State<NavSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Barrier to catch outside taps when open
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
        // Secondary FABs
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SecondaryFab(
              index: 2,
              controller: _controller,
              icon: Icons.settings,
              label: 'Settings',
              isActive: widget.activeDestination == NavDestination.settings,
              tokens: tokens,
              onTap: () {
                _close();
                widget.onSettingsTap?.call();
              },
            ),
            const SizedBox(height: 8),
            _SecondaryFab(
              index: 1,
              controller: _controller,
              icon: Icons.push_pin,
              label: 'Pins',
              isActive: widget.activeDestination == NavDestination.pins,
              tokens: tokens,
              onTap: () {
                _close();
                widget.onPinsTap?.call();
              },
            ),
            const SizedBox(height: 8),
            _SecondaryFab(
              index: 0,
              controller: _controller,
              icon: Icons.public,
              label: 'Map',
              isActive: widget.activeDestination == NavDestination.map,
              tokens: tokens,
              onTap: () {
                _close();
                widget.onMapTap?.call();
              },
            ),
            const SizedBox(height: 12),
            // Primary FAB
            SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: _toggle,
                backgroundColor: tokens.fabBackground,
                foregroundColor: tokens.fabIcon,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isOpen ? Icons.close : Icons.grid_view,
                    key: ValueKey(_isOpen),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryFab extends StatelessWidget {
  const _SecondaryFab({
    required this.index,
    required this.controller,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.tokens,
    required this.onTap,
  });

  final int index;
  final AnimationController controller;
  final IconData icon;
  final String label;
  final bool isActive;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Stagger: item 0 starts at 0.0, item 1 at ~0.25, item 2 at ~0.50
    final begin = index * 0.25;
    final end = (begin + 0.5).clamp(0.0, 1.0);

    final scaleAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: scaleAnimation,
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.surfaceOverlay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: tokens.hudPrimary,
                    fontSize: 12,
                    fontFamily: tokens.hudFontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Secondary FAB
              SizedBox(
                width: 40,
                height: 40,
                child: FloatingActionButton(
                  heroTag: 'nav_speed_dial_$label',
                  onPressed: onTap,
                  backgroundColor:
                      isActive ? tokens.hudPrimary : tokens.fabBackground,
                  foregroundColor:
                      isActive ? tokens.fabIcon : tokens.fabIcon,
                mini: true,
                child: Icon(icon, size: 20),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
