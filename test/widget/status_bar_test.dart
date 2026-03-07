import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/position_controller.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/shared/status_bar.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap(PositionSourceStatus status) {
  return ProviderScope(
    overrides: [
      positionControllerProvider.overrideWith(
        () => _FakePositionController(status),
      ),
    ],
    child: MaterialApp(
      theme: buildThemeData(AppThemes.night),
      home: const Scaffold(body: StatusBar()),
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
  group('StatusBar', () {
    testWidgets('shows "ISS Live" with green for live source',
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

    testWidgets('shows "Estimated (TLE)" with amber for estimated source',
        (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.estimated,
        isLive: false,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Estimated (TLE)'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Estimated (TLE)'));
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
      final fixTime = DateTime.now().toUtc().subtract(const Duration(seconds: 5));
      await tester.pumpWidget(_wrap(PositionSourceStatus(
        sourceType: PositionSourceType.live,
        isLive: true,
        lastFixAt: fixTime,
      )));
      // Pump once more to let the age timer fire.
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Updated'), findsOneWidget);
    });

    testWidgets('container height is 40', (tester) async {
      await tester.pumpWidget(_wrap(const PositionSourceStatus(
        sourceType: PositionSourceType.live,
        isLive: true,
        lastFixAt: null,
      )));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusBar),
          matching: find.byType(Container).first,
        ),
      );
      final constraints = container.constraints;
      expect(constraints?.maxHeight ?? container.constraints?.minHeight, 40);
    });
  });
}
