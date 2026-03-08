import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/hud_visibility_provider.dart';
import 'package:what_on_earth/shared/telemetry_hud.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap({bool visible = true}) {
  return ProviderScope(
    overrides: [
      hudVisibilityProvider.overrideWith(() => _FakeHudVisibility(visible)),
    ],
    child: MaterialApp(
      theme: buildThemeData(AppThemes.night),
      home: const Scaffold(body: TelemetryHud()),
    ),
  );
}

class _FakeHudVisibility extends HudVisibilityNotifier {
  _FakeHudVisibility(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TelemetryHud (WOE-070)', () {
    testWidgets('renders CustomPaint when visibility ON', (tester) async {
      await tester.pumpWidget(_wrap(visible: true));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is HudPainter),
        findsOneWidget,
      );
    });

    testWidgets('renders SizedBox.shrink when visibility OFF', (tester) async {
      await tester.pumpWidget(_wrap(visible: false));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is HudPainter),
        findsNothing,
      );
    });
  });

  group('HudVisibilityNotifier', () {
    test('default is true', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(hudVisibilityProvider), isTrue);
    });

    test('toggle flips state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(hudVisibilityProvider), isTrue);
      await container.read(hudVisibilityProvider.notifier).toggle();
      expect(container.read(hudVisibilityProvider), isFalse);
    });

    test('toggle persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(hudVisibilityProvider.notifier).toggle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hud_visible'), isFalse);
    });

    test('loads persisted value on build', () async {
      SharedPreferences.setMockInitialValues({'hud_visible': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial synchronous state is true (default)
      expect(container.read(hudVisibilityProvider), isTrue);

      // Pump microtask queue so _loadSaved() completes
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hudVisibilityProvider), isFalse);
    });
  });
}
