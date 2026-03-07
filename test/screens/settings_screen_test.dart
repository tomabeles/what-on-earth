import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/position/position_controller.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/screens/settings_screen.dart';

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
    // Emit on next microtask so PositionController._switchTo attaches the
    // listener before the event fires (broadcast streams discard events with
    // no listeners).
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

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeLive = _FakePositionSource(PositionSourceType.live);
      fakeTle = _FakePositionSource(PositionSourceType.estimated);
      fakeStatic = _FakePositionSource(PositionSourceType.static);
    });

    Widget buildApp() {
      return ProviderScope(
        overrides: [
          livePositionSourceProvider.overrideWithValue(fakeLive),
          tlePositionSourceProvider.overrideWithValue(fakeTle),
          staticPositionSourceProvider.overrideWithValue(fakeStatic),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets('shows Position Source section with segmented button',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Position Source'), findsOneWidget);
      expect(find.text('Live ISS'), findsOneWidget);
      expect(find.text('TLE'), findsOneWidget);
      expect(find.text('Static'), findsOneWidget);
    });

    testWidgets('static fields hidden by default (Live selected)',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Latitude'), findsNothing);
      expect(find.text('Longitude'), findsNothing);
      expect(find.text('Altitude'), findsNothing);
    });

    testWidgets('selecting Static shows coordinate fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Static'));
      await tester.pumpAndSettle();

      expect(find.text('Latitude'), findsOneWidget);
      expect(find.text('Longitude'), findsOneWidget);
      expect(find.text('Altitude'), findsOneWidget);
    });

    testWidgets('selecting Live hides coordinate fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Static'));
      await tester.pumpAndSettle();
      expect(find.text('Latitude'), findsOneWidget);

      await tester.tap(find.text('Live ISS'));
      await tester.pumpAndSettle();
      expect(find.text('Latitude'), findsNothing);
    });

    testWidgets('TLE mode does not show coordinate fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('TLE'));
      await tester.pumpAndSettle();

      expect(find.text('Latitude'), findsNothing);
    });
  });
}
