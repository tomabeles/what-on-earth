import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/position/position_controller.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/screens/settings_screen.dart';
import 'package:what_on_earth/shared/theme.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakePositionSource implements PositionSource {
  _FakePositionSource(this.type);

  @override
  final PositionSourceType type;

  final _controller = StreamController<OrbitalPosition>.broadcast();

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
    scheduleMicrotask(() {
      if (!_controller.isClosed) {
        _controller.add(OrbitalPosition(
          latDeg: 51.5,
          lonDeg: -0.1,
          altKm: 420,
          timestamp: DateTime.now().toUtc(),
          sourceType: type,
        ));
      }
    });
  }

  @override
  Future<void> stop() async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SettingsScreen — Position Source', () {
    late _FakePositionSource fakeLive;
    late _FakePositionSource fakeTle;
    late _FakePositionSource fakeStatic;
    late _FakePositionSource fakeGps;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeLive = _FakePositionSource(PositionSourceType.live);
      fakeTle = _FakePositionSource(PositionSourceType.estimated);
      fakeStatic = _FakePositionSource(PositionSourceType.static);
      fakeGps = _FakePositionSource(PositionSourceType.gps);
    });

    Widget buildApp() {
      return ProviderScope(
        overrides: [
          livePositionSourceProvider.overrideWithValue(fakeLive),
          tlePositionSourceProvider.overrideWithValue(fakeTle),
          staticPositionSourceProvider.overrideWithValue(fakeStatic),
          gpsPositionSourceProvider.overrideWithValue(fakeGps),
        ],
        child: MaterialApp(
          theme: buildThemeData(AppThemes.night),
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets('shows POSITION SOURCE with ISS, GPS, STATIC buttons',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('POSITION SOURCE'), findsOneWidget);
      expect(find.text('ISS'), findsOneWidget);
      expect(find.text('GPS'), findsOneWidget);
      expect(find.text('STATIC'), findsOneWidget);
      // TLE is not shown — it's automatic
      expect(find.text('TLE'), findsNothing);
    });

    testWidgets('tapping STATIC opens dialog', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('STATIC'));
      await tester.pumpAndSettle();

      expect(find.text('STATIC POSITION'), findsOneWidget);
      expect(find.text('COORDINATES'), findsOneWidget);
      expect(find.text('ADDRESS'), findsOneWidget);
    });

    testWidgets('static dialog can be dismissed with X', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('STATIC'));
      await tester.pumpAndSettle();
      expect(find.text('STATIC POSITION'), findsOneWidget);

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
      expect(find.text('STATIC POSITION'), findsNothing);
    });
  });
}
