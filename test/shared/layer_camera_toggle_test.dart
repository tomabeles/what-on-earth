import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/layer_control_panel.dart';

void main() {
  group('Stars toggle via layerVisibilityProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('stars defaults to ON', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final visibility = container.read(layerVisibilityProvider);
      expect(visibility['stars'], isTrue);
    });

    test('toggling stars flips its state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(layerVisibilityProvider)['stars'], isTrue);

      await container.read(layerVisibilityProvider.notifier).toggle('stars');
      expect(container.read(layerVisibilityProvider)['stars'], isFalse);

      await container.read(layerVisibilityProvider.notifier).toggle('stars');
      expect(container.read(layerVisibilityProvider)['stars'], isTrue);
    });

    test('stars state is persisted to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(layerVisibilityProvider.notifier).toggle('stars');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('layer_visible_stars'), isFalse);
    });
  });
}
