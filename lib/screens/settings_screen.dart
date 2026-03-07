import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../position/position_controller.dart';
import '../position/position_source.dart';
import '../shared/theme.dart';

/// Settings screen — grouped list (UI_SPEC §4.6).
///
/// Phase B1 implements the Position Source section only. Other sections
/// (Display, Layers, Tile Cache, Account, Sensor, Power, About) are added
/// in later tickets.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: tokens?.surfacePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PositionSourceSection(),
        ],
      ),
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

  // Local selection state for immediate UI response; the provider is
  // updated asynchronously in the background.
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
    final tokens = Theme.of(context).extension<AppTokens>();
    // Watch the provider to stay in sync if it changes externally.
    final asyncStatus = ref.watch(positionControllerProvider);
    final status = asyncStatus.value;
    final selected =
        _localSelection ?? status?.sourceType ?? PositionSourceType.live;

    return Card(
      color: tokens?.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens?.borderPrimary ?? Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Position Source',
              style: TextStyle(
                color: tokens?.hudPrimary ?? Colors.white,
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
                      return tokens?.fabIcon ?? Colors.black;
                    }
                    return tokens?.hudPrimary ?? Colors.white;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return tokens?.hudPrimary ?? Colors.white;
                    }
                    return tokens?.surfaceSecondary ?? Colors.black;
                  }),
                ),
              ),
            ),
            if (selected == PositionSourceType.static && _loadedDefaults)
              _buildStaticFields(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticFields(AppTokens? tokens) {
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
  final AppTokens? tokens;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: TextStyle(color: tokens?.hudPrimary ?? Colors.white),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: TextStyle(color: tokens?.hudSecondary ?? Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: tokens?.borderPrimary ?? Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens?.hudPrimary ?? Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens?.hudDanger ?? Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens?.hudDanger ?? Colors.red),
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
