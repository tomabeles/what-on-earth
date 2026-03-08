import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/position_controller.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/shared/status_bar.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap(PositionSourceStatus status, {DateTime? lastTileSync}) {
  return ProviderScope(
    overrides: [
      positionControllerProvider.overrideWith(
        () => _FakePositionController(status),
      ),
    ],
    child: MaterialApp(
      theme: buildThemeData(AppThemes.night),
      home: Scaffold(
          body: Center(child: StatusBar(lastTileSync: lastTileSync))),
    ),
  );
}

class _FakePositionController extends PositionController {
  _FakePositionController(this._status);
  final PositionSourceStatus _status;

  @override
  Future<PositionSourceStatus> build() async => _status;
}

void main() {
  group('StatusBar (WOE-067)', () {
    testWidgets('shows "ISS Live" with green dot for live source',
        (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.live,
        isLive: true,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      expect(find.text('ISS Live'), findsOneWidget);

      final text = tester.widget<Text>(find.text('ISS Live'));
      expect(text.style?.color, AppThemes.night.tokens.statusLive);
    });

    testWidgets('shows "TLE Estimated" with amber for estimated source',
        (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.estimated,
        isLive: false,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      expect(find.text('TLE Estimated'), findsOneWidget);

      final text = tester.widget<Text>(find.text('TLE Estimated'));
      expect(text.style?.color, AppThemes.night.tokens.statusEstimated);
    });

    testWidgets('shows "Static" with grey for static source', (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.static,
        isLive: false,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Static'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Static'));
      expect(text.style?.color, AppThemes.night.tokens.statusOffline);
    });

    testWidgets('shows age label when lastFixAt is provided', (tester) async {
      final fixTime =
          DateTime.now().toUtc().subtract(const Duration(seconds: 5));
      await tester.pumpWidget(_wrap(PositionSourceStatus(
        sourceType: PositionSourceType.live,
        isLive: true,
        lastFixAt: fixTime,
      )));
      // Pump once more to let the age timer fire.
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('has pill shape with border radius', (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.live,
        isLive: true,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      // Find the StatusBar's container and verify pill shape decoration
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusBar),
          matching: find.byType(Container).first,
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(14));
    });

    testWidgets('shows wifi icon when online', (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.live,
        isLive: true,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('shows Stale warning when tile cache is old', (tester) async {
      final oldSync =
          DateTime.now().toUtc().subtract(const Duration(days: 45));
      await tester.pumpWidget(_wrap(
        const PositionSourceStatus(
          sourceType: PositionSourceType.live,
          isLive: true,
          lastFixAt: null,
        ),
        lastTileSync: oldSync,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Stale'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('no Stale warning when tile cache is recent', (tester) async {
      final recentSync =
          DateTime.now().toUtc().subtract(const Duration(days: 5));
      await tester.pumpWidget(_wrap(
        const PositionSourceStatus(
          sourceType: PositionSourceType.live,
          isLive: true,
          lastFixAt: null,
        ),
        lastTileSync: recentSync,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Stale'), findsNothing);
    });
  });
}
