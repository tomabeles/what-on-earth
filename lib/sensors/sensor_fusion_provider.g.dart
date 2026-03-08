// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_fusion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton [SensorFusionEngine] instance. Call `start()` before listening.

@ProviderFor(sensorFusionEngine)
final sensorFusionEngineProvider = SensorFusionEngineProvider._();

/// Singleton [SensorFusionEngine] instance. Call `start()` before listening.

final class SensorFusionEngineProvider extends $FunctionalProvider<
    SensorFusionEngine,
    SensorFusionEngine,
    SensorFusionEngine> with $Provider<SensorFusionEngine> {
  /// Singleton [SensorFusionEngine] instance. Call `start()` before listening.
  SensorFusionEngineProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sensorFusionEngineProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sensorFusionEngineHash();

  @$internal
  @override
  $ProviderElement<SensorFusionEngine> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SensorFusionEngine create(Ref ref) {
    return sensorFusionEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SensorFusionEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SensorFusionEngine>(value),
    );
  }
}

String _$sensorFusionEngineHash() =>
    r'b0c621a511ddd86471935b7c4ee99b0bd1bb6058';

/// Broadcast stream of fused orientation samples at ~50 Hz.
///
/// Automatically starts the engine on first listen.

@ProviderFor(orientationStream)
final orientationStreamProvider = OrientationStreamProvider._();

/// Broadcast stream of fused orientation samples at ~50 Hz.
///
/// Automatically starts the engine on first listen.

final class OrientationStreamProvider extends $FunctionalProvider<
        AsyncValue<DeviceOrientation>,
        DeviceOrientation,
        Stream<DeviceOrientation>>
    with
        $FutureModifier<DeviceOrientation>,
        $StreamProvider<DeviceOrientation> {
  /// Broadcast stream of fused orientation samples at ~50 Hz.
  ///
  /// Automatically starts the engine on first listen.
  OrientationStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'orientationStreamProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$orientationStreamHash();

  @$internal
  @override
  $StreamProviderElement<DeviceOrientation> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DeviceOrientation> create(Ref ref) {
    return orientationStream(ref);
  }
}

String _$orientationStreamHash() => r'3b335d45ec9976a1d65e345ea84b7ce706139236';
