import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/globe/bridge.dart';

void main() {
  group('BridgeController.buildDispatchSource', () {
    test('produces valid JavaScript with correct JSON for UPDATE_POSITION', () {
      const payload = <String, dynamic>{
        'lat': 51.5,
        'lon': -0.1,
        'altKm': 420,
        'source': 'test',
      };
      final source = BridgeController.buildDispatchSource(
        OutboundMessage.updatePosition,
        payload,
      );

      expect(source, contains("CustomEvent('flutter_message'"));

      // Extract and parse the detail JSON embedded in the JS source.
      final detailJson = source.split('detail: ')[1].split(' }));')[0];
      final detail = jsonDecode(detailJson) as Map<String, dynamic>;

      expect(detail['type'], 'UPDATE_POSITION');
      expect(detail['payload'], payload);
    });

    test('all OutboundMessage.messageName values are uppercase', () {
      for (final msg in OutboundMessage.values) {
        expect(
          msg.messageName,
          msg.messageName.toUpperCase(),
          reason: '${msg.name}.messageName must be uppercase',
        );
      }
    });

    test('all InboundMessage.handlerName values are uppercase', () {
      for (final msg in InboundMessage.values) {
        expect(
          msg.handlerName,
          msg.handlerName.toUpperCase(),
          reason: '${msg.name}.handlerName must be uppercase',
        );
      }
    });

    test('OutboundMessage message names are unique', () {
      final names = OutboundMessage.values.map((m) => m.messageName).toList();
      expect(names.toSet().length, names.length);
    });

    test('InboundMessage handler names are unique', () {
      final names = InboundMessage.values.map((m) => m.handlerName).toList();
      expect(names.toSet().length, names.length);
    });

    test('buildDispatchSource contains dispatchEvent call', () {
      final source = BridgeController.buildDispatchSource(
        OutboundMessage.updateOrientation,
        {'heading': 0.0, 'pitch': -90.0, 'roll': 0.0, 'ts': 0},
      );
      expect(source, contains('window.dispatchEvent'));
    });
  });
}
