import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/globe/bridge.dart';

void main() {
  group('BridgeController FPS (WOE-075)', () {
    test('fpsNotifier starts as null', () {
      final bridge = BridgeController();
      expect(bridge.fpsNotifier.value, isNull);
      bridge.dispose();
    });

    test('SET_SKYBOX message is produced by setSkybox', () async {
      final bridge = BridgeController();
      OutboundMessage? sentType;
      Map<String, dynamic>? sentPayload;

      BridgeController.onSend = (type, payload) {
        sentType = type;
        sentPayload = payload;
      };

      await bridge.setSkybox(true);

      expect(sentType, OutboundMessage.setSkybox);
      expect(sentPayload?['enabled'], true);

      await bridge.setSkybox(false);
      expect(sentPayload?['enabled'], false);

      BridgeController.onSend = null;
      bridge.dispose();
    });

    test('buildDispatchSource for SET_SKYBOX contains correct payload', () {
      final source = BridgeController.buildDispatchSource(
        OutboundMessage.setSkybox,
        {'enabled': true},
      );
      expect(source, contains('SET_SKYBOX'));
      expect(source, contains('"enabled":true'));
    });
  });
}
