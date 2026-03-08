import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../position/position_controller.dart';
import '../position/position_source.dart';
import '../shared/hud_visibility_provider.dart';
import '../shared/nav_speed_dial.dart';
import '../shared/theme.dart';
import '../shared/theme_provider.dart';

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
              _DisplaySection(),
              SizedBox(height: 16),
              _PositionSourceSection(),
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

// ---------------------------------------------------------------------------
// Display section (WOE-080)
// ---------------------------------------------------------------------------

class _DisplaySection extends ConsumerWidget {
  const _DisplaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final currentTheme = ref.watch(themeProvider);
    final hudVisible = ref.watch(hudVisibilityProvider);

    return _SectionCard(
      tokens: tokens,
      children: [
        Text(
          'Display',
          style: TextStyle(
            color: tokens.hudPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Theme picker
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppThemeRegistry.themes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final theme = AppThemeRegistry.themes[index];
              final isSelected = theme.id == currentTheme.id;
              return GestureDetector(
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(theme.id),
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: tokens.surfacePrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? tokens.hudPrimary : tokens.borderPrimary,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Accent color swatch
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.tokens.hudPrimary,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 14,
                                color: theme.tokens.fabIcon)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.displayName,
                        style: TextStyle(
                          color: tokens.hudPrimary,
                          fontSize: 10,
                          fontFamily: tokens.hudFontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // HUD toggle
        SwitchListTile(
          title: Text(
            'Telemetry HUD',
            style: TextStyle(color: tokens.hudPrimary),
          ),
          value: hudVisible,
          onChanged: (_) =>
              ref.read(hudVisibilityProvider.notifier).toggle(),
          activeTrackColor: tokens.hudPrimary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Position Source section (WOE-081)
// ---------------------------------------------------------------------------

class _PositionSourceSection extends ConsumerStatefulWidget {
  const _PositionSourceSection();

  @override
  ConsumerState<_PositionSourceSection> createState() =>
      _PositionSourceSectionState();
}

class _PositionSourceSectionState
    extends ConsumerState<_PositionSourceSection> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  late final TextEditingController _altController;
  bool _loadedDefaults = false;

  PositionSourceType? _localSelection;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController();
    _lonController = TextEditingController();
    _altController = TextEditingController();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _latController.text =
          (prefs.getDouble('static_lat') ?? 51.5).toString();
      _lonController.text =
          (prefs.getDouble('static_lon') ?? -0.1).toString();
      _altController.text =
          (prefs.getDouble('static_alt_km') ?? 420.0).toString();
      _loadedDefaults = true;
    });
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _altController.dispose();
    super.dispose();
  }

  void _onSourceChanged(PositionSourceType? type) {
    if (type == null) return;
    setState(() => _localSelection = type);
    _applySourceChange(type);
  }

  Future<void> _applySourceChange(PositionSourceType type) async {
    final notifier = ref.read(positionControllerProvider.notifier);
    if (type == PositionSourceType.static) {
      await _saveStaticCoords();
    }
    await notifier.setSourceMode(type);
  }

  Future<void> _saveStaticCoords() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final prefs = await SharedPreferences.getInstance();
    final lat = double.tryParse(_latController.text) ?? 51.5;
    final lon = double.tryParse(_lonController.text) ?? -0.1;
    final alt = double.tryParse(_altController.text) ?? 420.0;
    await prefs.setDouble('static_lat', lat);
    await prefs.setDouble('static_lon', lon);
    await prefs.setDouble('static_alt_km', alt);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final asyncStatus = ref.watch(positionControllerProvider);
    final status = asyncStatus.value;
    final selected =
        _localSelection ?? status?.sourceType ?? PositionSourceType.live;

    return _SectionCard(
      tokens: tokens,
      children: [
        Text(
          'Position Source',
          style: TextStyle(
            color: tokens.hudPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<PositionSourceType>(
            segments: const [
              ButtonSegment(
                value: PositionSourceType.live,
                label: Text('Live ISS'),
              ),
              ButtonSegment(
                value: PositionSourceType.estimated,
                label: Text('TLE'),
              ),
              ButtonSegment(
                value: PositionSourceType.static,
                label: Text('Static'),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (s) => _onSourceChanged(s.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return tokens.fabIcon;
                }
                return tokens.hudPrimary;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return tokens.hudPrimary;
                }
                return tokens.surfaceSecondary;
              }),
            ),
          ),
        ),
        if (selected == PositionSourceType.static && _loadedDefaults)
          _buildStaticFields(tokens),
      ],
    );
  }

  Widget _buildStaticFields(AppTokens tokens) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            _CoordField(
              controller: _latController,
              label: 'Latitude',
              suffix: '\u00B0',
              min: -90,
              max: 90,
              tokens: tokens,
              onSaved: _saveStaticCoords,
            ),
            const SizedBox(height: 8),
            _CoordField(
              controller: _lonController,
              label: 'Longitude',
              suffix: '\u00B0',
              min: -180,
              max: 180,
              tokens: tokens,
              onSaved: _saveStaticCoords,
            ),
            const SizedBox(height: 8),
            _CoordField(
              controller: _altController,
              label: 'Altitude',
              suffix: 'km',
              min: 0,
              max: 1000,
              tokens: tokens,
              onSaved: _saveStaticCoords,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.tokens, required this.children});

  final AppTokens tokens;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: tokens.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  const _CoordField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
    required this.tokens,
    required this.onSaved,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;
  final AppTokens tokens;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: TextStyle(color: tokens.hudPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: TextStyle(color: tokens.hudSecondary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.hudPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.hudDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.hudDanger),
        ),
      ),
      validator: (value) {
        final v = double.tryParse(value ?? '');
        if (v == null) return 'Enter a number';
        if (v < min || v > max) return '$label must be $min\u2013$max';
        return null;
      },
      onEditingComplete: onSaved,
    );
  }
}
