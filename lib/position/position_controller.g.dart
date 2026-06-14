// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the active [PositionSource] and exposes a unified position stream.
///
/// Automatic fallback (TECH_SPEC §7.1) walks the enabled sources in priority
/// order — **WhereTheISS.at → CelesTrak TLE → Manual lat/long** (+ optional
/// GPS) — defined by [kPositionSourceDescriptors] and filtered by
/// [enabledSourcesProvider]:
///
/// - A **watchdog** demotes the active source to the next enabled source when
///   it produces no fix within its [PositionSourceDescriptor.staleTimeout].
///   This guarantees the HUD always gets coordinates even if the live API is
///   unreachable from a cold start.
/// - A per-source **[CircuitBreaker]** backs off a failed source and schedules
///   occasional recovery probes ("retry WhereTheISS.at occasionally"). A probe
///   runs the higher-priority source *alongside* the current one; the first
///   fix promotes it back and the lower source is stopped, so there is no gap
///   in coverage.
///
/// [setSourceMode] pins a specific source (manual override); pass null to
/// resume automatic fallback.

@ProviderFor(PositionController)
final positionControllerProvider = PositionControllerProvider._();

/// Manages the active [PositionSource] and exposes a unified position stream.
///
/// Automatic fallback (TECH_SPEC §7.1) walks the enabled sources in priority
/// order — **WhereTheISS.at → CelesTrak TLE → Manual lat/long** (+ optional
/// GPS) — defined by [kPositionSourceDescriptors] and filtered by
/// [enabledSourcesProvider]:
///
/// - A **watchdog** demotes the active source to the next enabled source when
///   it produces no fix within its [PositionSourceDescriptor.staleTimeout].
///   This guarantees the HUD always gets coordinates even if the live API is
///   unreachable from a cold start.
/// - A per-source **[CircuitBreaker]** backs off a failed source and schedules
///   occasional recovery probes ("retry WhereTheISS.at occasionally"). A probe
///   runs the higher-priority source *alongside* the current one; the first
///   fix promotes it back and the lower source is stopped, so there is no gap
///   in coverage.
///
/// [setSourceMode] pins a specific source (manual override); pass null to
/// resume automatic fallback.
final class PositionControllerProvider
    extends $AsyncNotifierProvider<PositionController, PositionSourceStatus> {
  /// Manages the active [PositionSource] and exposes a unified position stream.
  ///
  /// Automatic fallback (TECH_SPEC §7.1) walks the enabled sources in priority
  /// order — **WhereTheISS.at → CelesTrak TLE → Manual lat/long** (+ optional
  /// GPS) — defined by [kPositionSourceDescriptors] and filtered by
  /// [enabledSourcesProvider]:
  ///
  /// - A **watchdog** demotes the active source to the next enabled source when
  ///   it produces no fix within its [PositionSourceDescriptor.staleTimeout].
  ///   This guarantees the HUD always gets coordinates even if the live API is
  ///   unreachable from a cold start.
  /// - A per-source **[CircuitBreaker]** backs off a failed source and schedules
  ///   occasional recovery probes ("retry WhereTheISS.at occasionally"). A probe
  ///   runs the higher-priority source *alongside* the current one; the first
  ///   fix promotes it back and the lower source is stopped, so there is no gap
  ///   in coverage.
  ///
  /// [setSourceMode] pins a specific source (manual override); pass null to
  /// resume automatic fallback.
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
    r'a98f10e0fd3676f442cc1ca193b2ee212b6fd288';

/// Manages the active [PositionSource] and exposes a unified position stream.
///
/// Automatic fallback (TECH_SPEC §7.1) walks the enabled sources in priority
/// order — **WhereTheISS.at → CelesTrak TLE → Manual lat/long** (+ optional
/// GPS) — defined by [kPositionSourceDescriptors] and filtered by
/// [enabledSourcesProvider]:
///
/// - A **watchdog** demotes the active source to the next enabled source when
///   it produces no fix within its [PositionSourceDescriptor.staleTimeout].
///   This guarantees the HUD always gets coordinates even if the live API is
///   unreachable from a cold start.
/// - A per-source **[CircuitBreaker]** backs off a failed source and schedules
///   occasional recovery probes ("retry WhereTheISS.at occasionally"). A probe
///   runs the higher-priority source *alongside* the current one; the first
///   fix promotes it back and the lower source is stopped, so there is no gap
///   in coverage.
///
/// [setSourceMode] pins a specific source (manual override); pass null to
/// resume automatic fallback.

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
