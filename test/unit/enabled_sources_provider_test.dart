import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/position/enabled_sources_provider.dart';
import 'package:what_on_earth/position/position_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('enabledSourcesProvider', () {
    test('defaults to ISS Live, TLE, and Manual (GPS off)', () {
      SharedPreferences.setMockInitialValues({});
      final c = makeContainer();
      final enabled = c.read(enabledSourcesProvider);
      expect(enabled, {
        PositionSourceType.live,
        PositionSourceType.estimated,
        PositionSourceType.static,
      });
      expect(enabled.contains(PositionSourceType.gps), isFalse);
    });

    test('toggle adds and removes a source', () async {
      SharedPreferences.setMockInitialValues({});
      final c = makeContainer();
      final notifier = c.read(enabledSourcesProvider.notifier);

      await notifier.toggle(PositionSourceType.gps); // add
      expect(c.read(enabledSourcesProvider).contains(PositionSourceType.gps),
          isTrue);

      await notifier.toggle(PositionSourceType.gps); // remove
      expect(c.read(enabledSourcesProvider).contains(PositionSourceType.gps),
          isFalse);
    });

    test('refuses to disable the last remaining source', () async {
      SharedPreferences.setMockInitialValues({});
      final c = makeContainer();
      final notifier = c.read(enabledSourcesProvider.notifier);

      await notifier.toggle(PositionSourceType.estimated);
      await notifier.toggle(PositionSourceType.static);
      expect(c.read(enabledSourcesProvider), {PositionSourceType.live});

      // The last one cannot be turned off.
      await notifier.toggle(PositionSourceType.live);
      expect(c.read(enabledSourcesProvider), {PositionSourceType.live});
    });

    test('persists and reloads the enabled set', () async {
      SharedPreferences.setMockInitialValues({});
      final c1 = ProviderContainer();
      await c1.read(enabledSourcesProvider.notifier).toggle(PositionSourceType.gps);
      c1.dispose();

      // A fresh container should load the persisted set.
      final c2 = makeContainer();
      c2.read(enabledSourcesProvider); // trigger build + async _loadSaved
      // Allow the async _loadSaved (awaits SharedPreferences) to complete.
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c2.read(enabledSourcesProvider).contains(PositionSourceType.gps),
          isTrue);
    });
  });
}
