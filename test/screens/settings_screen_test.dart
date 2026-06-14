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

    // The controller runs a periodic watchdog timer, so the tree never
    // "settles"; pump explicitly instead of pumpAndSettle.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('shows POSITION SOURCES with enable toggles and override row',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      expect(find.text('POSITION SOURCES'), findsOneWidget);
      // Enabled sources appear in both the toggle list and the override row.
      expect(find.text('ISS LIVE'), findsWidgets);
      expect(find.text('TLE'), findsWidgets);
      expect(find.text('MANUAL'), findsWidgets);
      // GPS is off by default → only the toggle row, not the override row.
      expect(find.text('GPS'), findsOneWidget);
      // Override controls.
      expect(find.text('ACTIVE SOURCE'), findsOneWidget);
      expect(find.text('AUTO'), findsOneWidget);
    });

    testWidgets('tapping EDIT opens the manual position dialog',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      await tester.tap(find.text('EDIT'));
      await settle(tester);

      expect(find.text('STATIC POSITION'), findsOneWidget);
      expect(find.text('COORDINATES'), findsOneWidget);
      expect(find.text('ADDRESS'), findsOneWidget);
    });

    testWidgets('manual position dialog can be dismissed with X',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      await tester.tap(find.text('EDIT'));
      await settle(tester);
      expect(find.text('STATIC POSITION'), findsOneWidget);

      await tester.tap(find.text('X'));
      await settle(tester);
      expect(find.text('STATIC POSITION'), findsNothing);
    });
  });
}
