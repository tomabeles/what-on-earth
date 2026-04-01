import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/onboarding/tile_download_step.dart';
import 'package:what_on_earth/shared/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({VoidCallback? onComplete}) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildThemeData(AppThemes.night),
        home: Scaffold(
          body: TileDownloadStep(onComplete: onComplete),
        ),
      ),
    );
  }

  group('TileDownloadStep', () {
    testWidgets('shows layer checkboxes', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Satellite Imagery'), findsOneWidget);
      expect(find.text('Night Lights'), findsOneWidget);
      expect(find.text('Dark Map'), findsOneWidget);
    });

    testWidgets('shows estimated total size', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Estimated total:'), findsOneWidget);
    });

    testWidgets('shows Download and Skip buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('unchecking a layer updates estimated size', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // All 3 layers selected: 150 + 80 + 40 = 270 MB
      expect(find.text('Estimated total: 270 MB'), findsOneWidget);

      // Uncheck "Night Lights" (second checkbox)
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Now: 150 + 40 = 190 MB
      expect(find.text('Estimated total: 190 MB'), findsOneWidget);
    });

    testWidgets('skip calls onComplete', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        buildTestWidget(onComplete: () => completed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('shows title and description', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Download Map Tiles'), findsOneWidget);
      expect(find.textContaining('offline use'), findsOneWidget);
    });
  });
}
