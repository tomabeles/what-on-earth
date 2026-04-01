import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'orientation_lock';

/// Orientation lock mode.
enum OrientationLock {
  landscape,
  portrait,
}

/// Riverpod provider controlling device orientation lock.
///
/// Default: [OrientationLock.landscape]. Persisted in SharedPreferences.
final orientationLockProvider =
    NotifierProvider<OrientationLockNotifier, OrientationLock>(
  OrientationLockNotifier.new,
);

class OrientationLockNotifier extends Notifier<OrientationLock> {
  @override
  OrientationLock build() {
    _loadSaved();
    _apply(OrientationLock.landscape);
    return OrientationLock.landscape;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      final mode = OrientationLock.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => OrientationLock.landscape,
      );
      state = mode;
      _apply(mode);
    }
  }

  Future<void> set(OrientationLock mode) async {
    state = mode;
    _apply(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  void _apply(OrientationLock mode) {
    switch (mode) {
      case OrientationLock.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      case OrientationLock.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
    }
  }
}
