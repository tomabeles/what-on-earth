import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------
// Layer definitions
// ---------------------------------------------------------------------------

/// Unique layer identifiers matching SharedPreferences keys
/// `layer_visible_{id}`.
class LayerDef {
  const LayerDef(this.id, this.label, {this.defaultOn = true});
  final String id;
  final String label;
  final bool defaultOn;
}

const _layers = [
  LayerDef('stars', 'STARS'),
  LayerDef('borders', 'BORDERS', defaultOn: false),
  LayerDef('water', 'WATER'),
];

/// Imagery base-layer options (mutually exclusive).
const _imageryOptions = [
  LayerDef('base', 'SATELLITE'),
  LayerDef('nightlights', 'NIGHT LIGHTS', defaultOn: false),
  LayerDef('darkmatter', 'DARK MATTER', defaultOn: false),
  LayerDef('bluemarble', 'BLUE MARBLE', defaultOn: false),
];

// ---------------------------------------------------------------------------
// Layer visibility provider
// ---------------------------------------------------------------------------

/// Riverpod provider holding the visibility state of all map layers.
///
/// Camera is always ON on cold launch (not read from prefs). All other layers
/// are persisted to SharedPreferences under `layer_visible_{id}`.
final layerVisibilityProvider =
    NotifierProvider<LayerVisibilityNotifier, Map<String, bool>>(
  LayerVisibilityNotifier.new,
);

class LayerVisibilityNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final defaults = <String, bool>{};
    for (final l in [..._layers, ..._imageryOptions]) {
      defaults[l.id] = l.defaultOn;
    }
    _loadFromPrefs(defaults);
    return defaults;
  }

  Future<void> _loadFromPrefs(Map<String, bool> defaults) async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final updated = Map<String, bool>.from(defaults);
    for (final l in [..._layers, ..._imageryOptions]) {
      final stored = prefs.getBool('layer_visible_${l.id}');
      if (stored != null) updated[l.id] = stored;
    }
    state = updated;
  }

  Future<void> toggle(String layerId) async {
    final current = state[layerId] ?? true;
    state = {...state, layerId: !current};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('layer_visible_$layerId', !current);
  }

  /// Switch imagery base layer (mutually exclusive).
  ///
  /// The satellite base layer always stays visible underneath so the globe
  /// is never empty (other layers' tiles may not be downloaded yet).
  /// Selecting satellite hides all overlays; selecting another layer shows
  /// it on top of satellite.
  Future<void> setImagery(String layerId) async {
    final updated = Map<String, bool>.from(state);
    // Satellite base always stays on.
    updated['base'] = true;
    // Show only the selected overlay (hide the rest).
    for (final opt in _imageryOptions) {
      if (opt.id == 'base') continue;
      updated[opt.id] = opt.id == layerId;
    }
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    for (final opt in _imageryOptions) {
      await prefs.setBool('layer_visible_${opt.id}', updated[opt.id]!);
    }
  }

  /// The currently active imagery layer ID.
  /// Checks non-base options first since base stays visible as a fallback.
  String get activeImagery {
    for (final opt in _imageryOptions) {
      if (opt.id == 'base') continue;
      if (state[opt.id] == true) return opt.id;
    }
    return 'base';
  }
}

// ---------------------------------------------------------------------------
// LayerControlPanel widget
// ---------------------------------------------------------------------------

/// Bare list of layer toggle switches — no container chrome.
/// Reusable inside different shell widgets (modals, panels, etc.).
class LayerToggles extends ConsumerWidget {
  const LayerToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final visibility = ref.watch(layerVisibilityProvider);
    final notifier = ref.read(layerVisibilityProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Imagery base-layer selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMAGERY',
                style: TextStyle(
                  color: tokens.hudPrimary,
                  fontFamily: tokens.hudFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // 2×2 grid of equal-sized imagery buttons
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: 6),
                Row(
                  children: [
                    for (var col = 0; col < 2; col++) ...[
                      if (col > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _ImageryButton(
                          label: _imageryOptions[row * 2 + col].label,
                          isSelected: notifier.activeImagery ==
                              _imageryOptions[row * 2 + col].id,
                          tokens: tokens,
                          onTap: () => notifier.setImagery(
                              _imageryOptions[row * 2 + col].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Overlay layer toggles
        for (final layer in _layers)
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      layer.label,
                      style: TextStyle(
                        color: tokens.hudPrimary,
                        fontFamily: tokens.hudFontFamily,
                        fontSize: tokens.hudFontSize,
                      ),
                    ),
                  ),
                  SquareToggle(
                    value: visibility[layer.id] ?? layer.defaultOn,
                    onChanged: () => notifier.toggle(layer.id),
                    tokens: tokens,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Left-anchored overlay above Controls button with toggle switches.
///
/// Reference: UI_SPEC SS5.3
class LayerControlPanel extends ConsumerWidget {
  const LayerControlPanel({
    super.key,
    this.onClose,
  });

  /// Called when the panel should close.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: tokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const LayerToggles(),
    );
  }
}

/// Square button for imagery layer selection (mutually exclusive).
class _ImageryButton extends StatelessWidget {
  const _ImageryButton({
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
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.hudPrimary.withValues(alpha: 0.25)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? tokens.hudPrimary : const Color(0xBFC0C0C0),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
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

/// Square on/off toggle matching the fighter-jet cockpit aesthetic.
class SquareToggle extends StatelessWidget {
  const SquareToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.tokens,
  });

  final bool value;
  final VoidCallback onChanged;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          color: value
              ? tokens.hudPrimary.withValues(alpha: 0.25)
              : Colors.transparent,
          border: Border.all(
            color: const Color(0xBFC0C0C0),
            width: 1,
          ),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 20,
            color: value ? tokens.hudPrimary : tokens.hudSecondary,
          ),
        ),
      ),
    );
  }
}
