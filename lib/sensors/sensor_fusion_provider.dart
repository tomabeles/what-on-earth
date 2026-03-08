import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sensor_fusion.dart';

part 'sensor_fusion_provider.g.dart';

/// Singleton [SensorFusionEngine] instance. Call `start()` before listening.
@Riverpod(keepAlive: true)
SensorFusionEngine sensorFusionEngine(Ref ref) {
  final engine = SensorFusionEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
}

/// Broadcast stream of fused orientation samples at ~50 Hz.
///
/// Automatically starts the engine on first listen.
@Riverpod(keepAlive: true)
Stream<DeviceOrientation> orientationStream(Ref ref) {
  final engine = ref.watch(sensorFusionEngineProvider);
  if (!engine.isRunning) {
    engine.start();
  }
  return engine.orientationStream;
}
