import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/layer_control_panel.dart';

void main() {
  group('Camera toggle via layerVisibilityProvider (WOE-077)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('camera defaults to ON on cold launch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final visibility = container.read(layerVisibilityProvider);
      expect(visibility['camera'], isTrue);
    });

    test('toggling camera flips its state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(layerVisibilityProvider)['camera'], isTrue);

      await container.read(layerVisibilityProvider.notifier).toggle('camera');
      expect(container.read(layerVisibilityProvider)['camera'], isFalse);

      await container.read(layerVisibilityProvider.notifier).toggle('camera');
      expect(container.read(layerVisibilityProvider)['camera'], isTrue);
    });

    test('camera state is NOT persisted to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(layerVisibilityProvider.notifier).toggle('camera');
      final prefs = await SharedPreferences.getInstance();
      // Camera should NOT be persisted (always ON on cold launch)
      expect(prefs.getBool('layer_visible_camera'), isNull);
    });

    test('non-camera layer toggle IS persisted', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Rivers default to OFF
      expect(container.read(layerVisibilityProvider)['rivers'], isFalse);

      await container.read(layerVisibilityProvider.notifier).toggle('rivers');
      expect(container.read(layerVisibilityProvider)['rivers'], isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('layer_visible_rivers'), isTrue);
    });
  });
}
