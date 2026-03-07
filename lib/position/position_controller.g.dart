// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Production [ISSLiveSource] instance. Override in tests with a fake.

@ProviderFor(livePositionSource)
final livePositionSourceProvider = LivePositionSourceProvider._();

/// Production [ISSLiveSource] instance. Override in tests with a fake.

final class LivePositionSourceProvider
    extends $FunctionalProvider<PositionSource, PositionSource, PositionSource>
    with $Provider<PositionSource> {
  /// Production [ISSLiveSource] instance. Override in tests with a fake.
  LivePositionSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'livePositionSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$livePositionSourceHash();

  @$internal
  @override
  $ProviderElement<PositionSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PositionSource create(Ref ref) {
    return livePositionSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PositionSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PositionSource>(value),
    );
  }
}

String _$livePositionSourceHash() =>
    r'aee6b461ff8621eb6358a97751fc220104d30c2d';

/// Production [TLESource] instance. Override in tests with a fake.
///
/// NOTE: The [BridgeController] here is a transient instance. It will be
/// replaced with a shared bridge provider in WOE-014.

@ProviderFor(tlePositionSource)
final tlePositionSourceProvider = TlePositionSourceProvider._();

/// Production [TLESource] instance. Override in tests with a fake.
///
/// NOTE: The [BridgeController] here is a transient instance. It will be
/// replaced with a shared bridge provider in WOE-014.

final class TlePositionSourceProvider
    extends $FunctionalProvider<PositionSource, PositionSource, PositionSource>
    with $Provider<PositionSource> {
  /// Production [TLESource] instance. Override in tests with a fake.
  ///
  /// NOTE: The [BridgeController] here is a transient instance. It will be
  /// replaced with a shared bridge provider in WOE-014.
  TlePositionSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tlePositionSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tlePositionSourceHash();

  @$internal
  @override
  $ProviderElement<PositionSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PositionSource create(Ref ref) {
    return tlePositionSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PositionSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PositionSource>(value),
    );
  }
}

String _$tlePositionSourceHash() => r'37127cfbab520b5aa5b977bd7b9089ae6aca710e';

/// Static coordinates stored in SharedPreferences. Defaults to ISS orbital
/// altitude over London (51.5°N, −0.1°E, 420 km). Updated via Settings
/// screen (WOE-049).

@ProviderFor(staticCoordinates)
final staticCoordinatesProvider = StaticCoordinatesProvider._();

/// Static coordinates stored in SharedPreferences. Defaults to ISS orbital
/// altitude over London (51.5°N, −0.1°E, 420 km). Updated via Settings
/// screen (WOE-049).

final class StaticCoordinatesProvider extends $FunctionalProvider<
        AsyncValue<
            ({
              double altKm,
              double lat,
              double lon,
            })>,
        ({
          double altKm,
          double lat,
          double lon,
        }),
        FutureOr<
            ({
              double altKm,
              double lat,
              double lon,
            })>>
    with
        $FutureModifier<
            ({
              double altKm,
              double lat,
              double lon,
            })>,
        $FutureProvider<
            ({
              double altKm,
              double lat,
              double lon,
            })> {
  /// Static coordinates stored in SharedPreferences. Defaults to ISS orbital
  /// altitude over London (51.5°N, −0.1°E, 420 km). Updated via Settings
  /// screen (WOE-049).
  StaticCoordinatesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'staticCoordinatesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$staticCoordinatesHash();

  @$internal
  @override
  $FutureProviderElement<
      ({
        double altKm,
        double lat,
        double lon,
      })> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<
      ({
        double altKm,
        double lat,
        double lon,
      })> create(Ref ref) {
    return staticCoordinates(ref);
  }
}

String _$staticCoordinatesHash() => r'56d4526e81aa78ac8e9c65baac8050303c09a941';

/// Production [StaticPositionSource] instance. Override in tests with a fake.

@ProviderFor(staticPositionSource)
final staticPositionSourceProvider = StaticPositionSourceProvider._();

/// Production [StaticPositionSource] instance. Override in tests with a fake.

final class StaticPositionSourceProvider
    extends $FunctionalProvider<PositionSource, PositionSource, PositionSource>
    with $Provider<PositionSource> {
  /// Production [StaticPositionSource] instance. Override in tests with a fake.
  StaticPositionSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'staticPositionSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$staticPositionSourceHash();

  @$internal
  @override
  $ProviderElement<PositionSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PositionSource create(Ref ref) {
    return staticPositionSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PositionSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PositionSource>(value),
    );
  }
}

String _$staticPositionSourceHash() =>
    r'3c61e9729f78bca6c8e55b618e5c7b423a91f29e';

/// Manages the active [PositionSource] and exposes a unified position stream.
///
/// State is [AsyncValue<PositionSourceStatus>]; it is `loading` briefly while
/// [build] starts [ISSLiveSource], then transitions to `data` once the first
/// source is active. Use `ref.watch(positionControllerProvider.future)` to
/// await initial readiness.
///
/// Start-up behaviour (TECH_SPEC §7.1):
/// - Begins with [livePositionSourceProvider].
/// - After [_kFallbackThreshold] consecutive `estimated` positions, switches
///   to [tlePositionSourceProvider].
/// - On the first `live` position while TLE is active, switches back.
///
/// [setSourceMode] lets the settings screen pin a specific source.

@ProviderFor(PositionController)
final positionControllerProvider = PositionControllerProvider._();

/// Manages the active [PositionSource] and exposes a unified position stream.
///
/// State is [AsyncValue<PositionSourceStatus>]; it is `loading` briefly while
/// [build] starts [ISSLiveSource], then transitions to `data` once the first
/// source is active. Use `ref.watch(positionControllerProvider.future)` to
/// await initial readiness.
///
/// Start-up behaviour (TECH_SPEC §7.1):
/// - Begins with [livePositionSourceProvider].
/// - After [_kFallbackThreshold] consecutive `estimated` positions, switches
///   to [tlePositionSourceProvider].
/// - On the first `live` position while TLE is active, switches back.
///
/// [setSourceMode] lets the settings screen pin a specific source.
final class PositionControllerProvider
    extends $AsyncNotifierProvider<PositionController, PositionSourceStatus> {
  /// Manages the active [PositionSource] and exposes a unified position stream.
  ///
  /// State is [AsyncValue<PositionSourceStatus>]; it is `loading` briefly while
  /// [build] starts [ISSLiveSource], then transitions to `data` once the first
  /// source is active. Use `ref.watch(positionControllerProvider.future)` to
  /// await initial readiness.
  ///
  /// Start-up behaviour (TECH_SPEC §7.1):
  /// - Begins with [livePositionSourceProvider].
  /// - After [_kFallbackThreshold] consecutive `estimated` positions, switches
  ///   to [tlePositionSourceProvider].
  /// - On the first `live` position while TLE is active, switches back.
  ///
  /// [setSourceMode] lets the settings screen pin a specific source.
  PositionControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'positionControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$positionControllerHash();

  @$internal
  @override
  PositionController create() => PositionController();
}

String _$positionControllerHash() =>
    r'4747d06ef93735b9ddd4ad0d1e9eb00c1bde3f22';

/// Manages the active [PositionSource] and exposes a unified position stream.
///
/// State is [AsyncValue<PositionSourceStatus>]; it is `loading` briefly while
/// [build] starts [ISSLiveSource], then transitions to `data` once the first
/// source is active. Use `ref.watch(positionControllerProvider.future)` to
/// await initial readiness.
///
/// Start-up behaviour (TECH_SPEC §7.1):
/// - Begins with [livePositionSourceProvider].
/// - After [_kFallbackThreshold] consecutive `estimated` positions, switches
///   to [tlePositionSourceProvider].
/// - On the first `live` position while TLE is active, switches back.
///
/// [setSourceMode] lets the settings screen pin a specific source.

abstract class _$PositionController
    extends $AsyncNotifier<PositionSourceStatus> {
  FutureOr<PositionSourceStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<PositionSourceStatus>, PositionSourceStatus>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PositionSourceStatus>, PositionSourceStatus>,
        AsyncValue<PositionSourceStatus>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
