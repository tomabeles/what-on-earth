import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'position_source.dart';
import 'position_source_registry.dart';

const _prefKey = 'enabled_position_sources';

/// The set of position sources the user has enabled for automatic fallback.
///
/// At least one source is always enabled — disabling the last one is a no-op.
/// Persisted to SharedPreferences as a comma-joined list of
/// [PositionSourceType] names. Defaults to every descriptor whose
/// [PositionSourceDescriptor.defaultEnabled] is true (ISS Live, TLE, Manual;
/// GPS off).
///
/// The [PositionController] watches this provider and rebuilds its fallback
/// chain whenever the enabled set changes.
final enabledSourcesProvider =
    NotifierProvider<EnabledSourcesNotifier, Set<PositionSourceType>>(
  EnabledSourcesNotifier.new,
);

class EnabledSourcesNotifier extends Notifier<Set<PositionSourceType>> {
  @override
  Set<PositionSourceType> build() {
    _loadSaved();
    return {
      for (final d in kPositionSourceDescriptors)
        if (d.defaultEnabled) d.type,
    };
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return;

    final parsed = <PositionSourceType>{};
    for (final name in raw.split(',')) {
      final type = PositionSourceType.values
          .where((t) => t.name == name)
          .firstOrNull;
      if (type != null && descriptorFor(type) != null) parsed.add(type);
    }
    if (parsed.isNotEmpty) state = parsed;
  }

  /// Toggles [type] on or off. Disabling the final enabled source is refused so
  /// that at least one source always remains active.
  Future<void> toggle(PositionSourceType type) async {
    final next = Set<PositionSourceType>.from(state);
    if (next.contains(type)) {
      if (next.length == 1) return; // never disable the last source
      next.remove(type);
    } else {
      next.add(type);
    }
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, state.map((t) => t.name).join(','));
  }
}
