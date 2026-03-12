import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../position/position_controller.dart';
import '../position/position_source.dart';
import 'camera_overlay_provider.dart';
import 'hud_visibility_provider.dart';
import 'layer_control_panel.dart';
import 'theme.dart';
import 'theme_provider.dart';

/// Settings body — reusable inside both SettingsScreen and HUD modal.
class SettingsBody extends ConsumerWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DisplaySection(),
        SizedBox(height: 12),
        PositionSourceSection(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Display section
// ---------------------------------------------------------------------------

class DisplaySection extends ConsumerWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final hudVisible = ref.watch(hudVisibilityProvider);
    final cameraOverlay = ref.watch(cameraOverlayProvider);
    ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DISPLAY',
          style: TextStyle(
            color: tokens.hudPrimary,
            fontFamily: tokens.hudFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'HUD COLOR',
              style: TextStyle(
                color: tokens.hudPrimary,
                fontFamily: tokens.hudFontFamily,
                fontSize: tokens.hudFontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _HueSlider(
          hue: notifier.hue,
          onChanged: (h) => notifier.setHue(h),
          tokens: tokens,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'TELEMETRY HUD',
                style: TextStyle(
                  color: tokens.hudPrimary,
                  fontFamily: tokens.hudFontFamily,
                  fontSize: tokens.hudFontSize,
                ),
              ),
            ),
            SquareToggle(
              value: hudVisible,
              onChanged: () =>
                  ref.read(hudVisibilityProvider.notifier).toggle(),
              tokens: tokens,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'CAMERA OVERLAY',
                style: TextStyle(
                  color: tokens.hudPrimary,
                  fontFamily: tokens.hudFontFamily,
                  fontSize: tokens.hudFontSize,
                ),
              ),
            ),
            SquareToggle(
              value: cameraOverlay,
              onChanged: () =>
                  ref.read(cameraOverlayProvider.notifier).toggle(),
              tokens: tokens,
            ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal hue slider — gray line with a circular colored thumb.
class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.onChanged,
    required this.tokens,
  });

  final double hue;
  final ValueChanged<double> onChanged;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanDown: (d) =>
                _update(d.localPosition.dx, constraints.maxWidth),
            onPanUpdate: (d) =>
                _update(d.localPosition.dx, constraints.maxWidth),
            child: CustomPaint(
              size: Size(constraints.maxWidth, 30),
              painter: _HueTrackPainter(hue: hue),
            ),
          );
        },
      ),
    );
  }

  void _update(double dx, double width) {
    const pad = 10.0;
    final clamped = dx.clamp(pad, width - pad);
    final t = (clamped - pad) / (width - 2 * pad);
    onChanged(t * 360.0);
  }
}

class _HueTrackPainter extends CustomPainter {
  const _HueTrackPainter({required this.hue});
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 10.0;
    final trackY = size.height / 2;
    final trackLeft = pad;
    final trackRight = size.width - pad;

    canvas.drawLine(
      Offset(trackLeft, trackY),
      Offset(trackRight, trackY),
      Paint()
        ..color = const Color(0xBFC0C0C0)
        ..strokeWidth = 2,
    );

    final t = hue / 360.0;
    final thumbX = trackLeft + t * (trackRight - trackLeft);
    final thumbColor =
        HSVColor.fromAHSV(1.0, hue % 360, 0.9, 1.0).toColor();

    canvas.drawCircle(
      Offset(thumbX, trackY),
      10,
      Paint()..color = thumbColor,
    );
    canvas.drawCircle(
      Offset(thumbX, trackY),
      10,
      Paint()
        ..color = const Color(0xBFC0C0C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_HueTrackPainter old) => old.hue != hue;
}

// ---------------------------------------------------------------------------
// Position Source section
// ---------------------------------------------------------------------------

class PositionSourceSection extends ConsumerStatefulWidget {
  const PositionSourceSection({super.key});

  @override
  ConsumerState<PositionSourceSection> createState() =>
      _PositionSourceSectionState();
}

class _PositionSourceSectionState
    extends ConsumerState<PositionSourceSection> {
  PositionSourceType? _localSelection;

  void _onSourceChanged(PositionSourceType type) {
    if (type == PositionSourceType.static) {
      // Open the static position modal instead of switching immediately
      _showStaticModal();
      return;
    }
    setState(() => _localSelection = type);
    ref.read(positionControllerProvider.notifier).setSourceMode(type);
  }

  void _showStaticModal() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _StaticPositionDialog(
        onApply: () {
          setState(() => _localSelection = PositionSourceType.static);
          ref
              .read(positionControllerProvider.notifier)
              .setSourceMode(PositionSourceType.static);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final asyncStatus = ref.watch(positionControllerProvider);
    final status = asyncStatus.value;
    final selected =
        _localSelection ?? status?.sourceType ?? PositionSourceType.live;
    // Map estimated back to ISS for display (TLE is automatic fallback)
    final displaySelected = selected == PositionSourceType.estimated
        ? PositionSourceType.live
        : selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'POSITION SOURCE',
          style: TextStyle(
            color: tokens.hudPrimary,
            fontFamily: tokens.hudFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _SourceSelector(
          selected: displaySelected,
          onChanged: _onSourceChanged,
          tokens: tokens,
        ),
      ],
    );
  }
}

/// Row of square buttons for selecting position source (no TLE — automatic).
class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.selected,
    required this.onChanged,
    required this.tokens,
  });

  final PositionSourceType selected;
  final ValueChanged<PositionSourceType> onChanged;
  final AppTokens tokens;

  static const _options = [
    (PositionSourceType.live, 'ISS'),
    (PositionSourceType.gps, 'GPS'),
    (PositionSourceType.static, 'STATIC'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _SourceButton(
              label: _options[i].$2,
              isSelected: selected == _options[i].$1,
              tokens: tokens,
              onTap: () => onChanged(_options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.hudPrimary.withValues(alpha: 0.25)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? tokens.hudPrimary
                : const Color(0xBFC0C0C0),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? tokens.hudPrimary : tokens.hudSecondary,
            fontFamily: tokens.hudFontFamily,
            fontSize: tokens.hudFontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Static Position Dialog — coordinate or address entry
// ---------------------------------------------------------------------------

/// Which entry mode is active in the static position dialog.
enum _StaticEntryMode { coordinates, address }

class _StaticPositionDialog extends StatefulWidget {
  const _StaticPositionDialog({required this.onApply});
  final VoidCallback onApply;

  @override
  State<_StaticPositionDialog> createState() => _StaticPositionDialogState();
}

class _StaticPositionDialogState extends State<_StaticPositionDialog> {
  _StaticEntryMode _mode = _StaticEntryMode.coordinates;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _altCtrl;
  late final TextEditingController _addressCtrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();
    _altCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _latCtrl.text = (prefs.getDouble('static_lat') ?? 51.5).toString();
      _lonCtrl.text = (prefs.getDouble('static_lon') ?? -0.1).toString();
      _altCtrl.text = (prefs.getDouble('static_alt_km') ?? 420.0).toString();
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _altCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoordinates() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        'static_lat', double.tryParse(_latCtrl.text) ?? 51.5);
    await prefs.setDouble(
        'static_lon', double.tryParse(_lonCtrl.text) ?? -0.1);
    await prefs.setDouble(
        'static_alt_km', double.tryParse(_altCtrl.text) ?? 420.0);
    widget.onApply();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _applyAddress() async {
    // TODO: geocode address to lat/lon using a geocoding service
    // For now, just dismiss
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            border: Border.all(color: const Color(0xBFC0C0C0), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and close
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'STATIC POSITION',
                      style: TextStyle(
                        color: tokens.hudPrimary,
                        fontFamily: tokens.hudFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'X',
                      style: TextStyle(
                        color: tokens.hudSecondary,
                        fontFamily: tokens.hudFontFamily,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mode selector
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      label: 'COORDINATES',
                      isSelected: _mode == _StaticEntryMode.coordinates,
                      tokens: tokens,
                      onTap: () => setState(
                          () => _mode = _StaticEntryMode.coordinates),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _SourceButton(
                      label: 'ADDRESS',
                      isSelected: _mode == _StaticEntryMode.address,
                      tokens: tokens,
                      onTap: () =>
                          setState(() => _mode = _StaticEntryMode.address),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Entry content
              if (_mode == _StaticEntryMode.coordinates && _loaded)
                _buildCoordFields(tokens)
              else if (_mode == _StaticEntryMode.address)
                _buildAddressField(tokens),
              const SizedBox(height: 12),
              // Apply button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _mode == _StaticEntryMode.coordinates
                      ? _applyCoordinates
                      : _applyAddress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: tokens.hudPrimary.withValues(alpha: 0.25),
                      border: Border.all(color: tokens.hudPrimary, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'APPLY',
                      style: TextStyle(
                        color: tokens.hudPrimary,
                        fontFamily: tokens.hudFontFamily,
                        fontSize: tokens.hudFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordFields(AppTokens tokens) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _CoordField(
            controller: _latCtrl,
            label: 'LATITUDE',
            suffix: '\u00B0',
            min: -90,
            max: 90,
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _CoordField(
            controller: _lonCtrl,
            label: 'LONGITUDE',
            suffix: '\u00B0',
            min: -180,
            max: 180,
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _CoordField(
            controller: _altCtrl,
            label: 'ALTITUDE',
            suffix: 'KM',
            min: 0,
            max: 1000,
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField(AppTokens tokens) {
    return TextFormField(
      controller: _addressCtrl,
      style: TextStyle(
        color: tokens.hudPrimary,
        fontFamily: tokens.hudFontFamily,
      ),
      decoration: InputDecoration(
        labelText: 'ADDRESS',
        hintText: 'CITY, COUNTRY',
        hintStyle: TextStyle(
          color: tokens.hudSecondary.withValues(alpha: 0.5),
          fontFamily: tokens.hudFontFamily,
        ),
        labelStyle: TextStyle(
          color: tokens.hudSecondary,
          fontFamily: tokens.hudFontFamily,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.hudPrimary),
        ),
      ),
    );
  }
}

/// Compact coordinate field for the static position dialog.
class _CoordField extends StatelessWidget {
  const _CoordField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
    required this.tokens,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: TextStyle(
          color: tokens.hudPrimary,
          fontFamily: tokens.hudFontFamily,
          fontSize: tokens.hudFontSize,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          labelStyle: TextStyle(
            color: tokens.hudSecondary,
            fontFamily: tokens.hudFontFamily,
            fontSize: tokens.hudFontSize,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.borderPrimary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.hudPrimary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.hudDanger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.hudDanger),
          ),
        ),
        validator: (value) {
          final v = double.tryParse(value ?? '');
          if (v == null) return 'Enter a number';
          if (v < min || v > max) return '$min\u2013$max';
          return null;
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers (kept for SettingsScreen standalone page)
// ---------------------------------------------------------------------------

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.tokens,
    required this.children,
  });

  final AppTokens tokens;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: const Color(0xBFC0C0C0), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class CoordField extends StatelessWidget {
  const CoordField({
    super.key,
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
      style: TextStyle(
        color: tokens.hudPrimary,
        fontFamily: tokens.hudFontFamily,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: TextStyle(
          color: tokens.hudSecondary,
          fontFamily: tokens.hudFontFamily,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.hudPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.hudDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
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
