import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:what_on_earth/globe/bridge.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // CesiumJS renders continuously via requestAnimationFrame, so pumpAndSettle
  // would never settle. All tests below poll with real-time delays instead.

  testWidgets('app launches and GlobeView is present in the widget tree',
      (tester) async {
    await pumpTestApp(tester);

    // Poll for up to 15 s for the InAppWebView to be mounted.
    const deadline = Duration(seconds: 15);
    const pollInterval = Duration(milliseconds: 500);
    final end = tester.binding.clock.now().add(deadline);

    while (tester.binding.clock.now().isBefore(end)) {
      await tester.pump(pollInterval);
      if (find.byKey(const Key('globe_view')).evaluate().isNotEmpty) break;
    }

    expect(find.byType(ErrorWidget), findsNothing,
        reason: 'No unhandled errors should appear on screen');
    expect(find.byKey(const Key('globe_view')), findsOneWidget,
        reason: 'GlobeView must be mounted within 15 s');
  });

  testWidgets('UPDATE_POSITION is dispatched from StaticPositionSource',
      (tester) async {
    final dispatched = <Map<String, dynamic>>[];

    BridgeController.onSend = (type, payload) {
      if (type == OutboundMessage.updatePosition) {
        dispatched.add(Map<String, dynamic>.from(payload));
      }
    };

    try {
      await pumpTestApp(tester);

      // StaticPositionSource emits every 5 s; poll for up to 10 s.
      const deadline = Duration(seconds: 10);
      const pollInterval = Duration(milliseconds: 200);
      final end = tester.binding.clock.now().add(deadline);

      while (dispatched.isEmpty && tester.binding.clock.now().isBefore(end)) {
        await tester.pump(pollInterval);
      }

      expect(dispatched, isNotEmpty,
          reason: 'At least one UPDATE_POSITION must be dispatched within 10 s');
      expect(dispatched.first['lat'], isA<double>());
      expect(dispatched.first['lon'], isA<double>());
      expect(dispatched.first['altKm'], isA<double>());
    } finally {
      BridgeController.onSend = null;
    }
  });
}
