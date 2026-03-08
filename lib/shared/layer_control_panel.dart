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
  LayerDef('camera', 'Camera'),
  LayerDef('relief', 'Relief shading'),
  LayerDef('clouds', 'Cloud cover'),
  LayerDef('borders', 'Country borders'),
  LayerDef('coastlines', 'Coastlines'),
  LayerDef('cities', 'Cities & labels'),
  LayerDef('rivers', 'Rivers & lakes', defaultOn: false),
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
    // Start with defaults; camera always ON
    final defaults = <String, bool>{};
    for (final l in _layers) {
      defaults[l.id] = l.id == 'camera' ? true : l.defaultOn;
    }
    _loadFromPrefs(defaults);
    return defaults;
  }

  Future<void> _loadFromPrefs(Map<String, bool> defaults) async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final updated = Map<String, bool>.from(defaults);
    for (final l in _layers) {
      if (l.id == 'camera') continue; // Camera always ON on cold launch
      final stored = prefs.getBool('layer_visible_${l.id}');
      if (stored != null) updated[l.id] = stored;
    }
    state = updated;
  }

  Future<void> toggle(String layerId) async {
    final current = state[layerId] ?? true;
    state = {...state, layerId: !current};
    if (layerId != 'camera') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('layer_visible_$layerId', !current);
    }
  }
}

// ---------------------------------------------------------------------------
// LayerControlPanel widget
// ---------------------------------------------------------------------------

/// Left-anchored overlay above Controls button with toggle switches.
///
/// Reference: UI_SPEC SS5.3
class LayerControlPanel extends ConsumerWidget {
  const LayerControlPanel({
    super.key,
    this.isMapMode = false,
    this.onClose,
  });

  /// When true, the Camera row is hidden.
  final bool isMapMode;

  /// Called when the panel should close.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final visibility = ref.watch(layerVisibilityProvider);
    final notifier = ref.read(layerVisibilityProvider.notifier);

    final visibleLayers =
        _layers.where((l) => !(isMapMode && l.id == 'camera')).toList();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: tokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final layer in visibleLayers)
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
                    Switch(
                      value: visibility[layer.id] ?? layer.defaultOn,
                      onChanged: (_) => notifier.toggle(layer.id),
                      activeTrackColor: tokens.hudPrimary,
                      inactiveTrackColor: tokens.borderPrimary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
