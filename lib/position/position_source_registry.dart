import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globe/bridge.dart';
import 'circuit_breaker.dart';
import 'gps_position_source.dart';
import 'iss_live_source.dart';
import 'position_source.dart';
import 'static_position_source.dart';
import 'tle_manager.dart';
import 'tle_source.dart';

part 'position_source_registry.g.dart';

// ── Source providers (overridable for testing) ────────────────────────────

/// Production [ISSLiveSource] instance. Override in tests with a fake.
@riverpod
PositionSource livePositionSource(Ref ref) => ISSLiveSource.create();

/// Production [TLESource] instance. Override in tests with a fake.
///
/// NOTE: The [BridgeController] here is a transient instance. It will be
/// replaced with a shared bridge provider in WOE-014.
@riverpod
PositionSource tlePositionSource(Ref ref) => _DeferredTleSource();

/// Static coordinates stored in SharedPreferences. Defaults to ISS orbital
/// altitude over London (51.5°N, −0.1°E, 420 km). Updated via Settings
/// screen (WOE-049).
@riverpod
Future<({double lat, double lon, double altKm})> staticCoordinates(
    Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return (
    lat: prefs.getDouble('static_lat') ?? 51.5,
    lon: prefs.getDouble('static_lon') ?? -0.1,
    altKm: prefs.getDouble('static_alt_km') ?? 420.0,
  );
}

/// Production [StaticPositionSource] instance. Override in tests with a fake.
@riverpod
PositionSource staticPositionSource(Ref ref) => _DeferredStaticSource(ref);

/// Production [GpsPositionSource] instance. Override in tests with a fake.
@riverpod
PositionSource gpsPositionSource(Ref ref) => GpsPositionSource();

/// Lazy-resolved [StaticPositionSource] that reads coordinates from
/// SharedPreferences on first [start].
class _DeferredStaticSource implements PositionSource {
  _DeferredStaticSource(this._ref);
  final Ref _ref;
  StaticPositionSource? _inner;

  @override
  PositionSourceType get type => PositionSourceType.static;

  @override
  Stream<OrbitalPosition> get positionStream =>
      _inner?.positionStream ?? const Stream.empty();

  @override
  Future<void> start() async {
    if (_inner == null) {
      final coords = await _ref.read(staticCoordinatesProvider.future);
      _inner = StaticPositionSource(
        position: OrbitalPosition(
          latDeg: coords.lat,
          lonDeg: coords.lon,
          altKm: coords.altKm,
          timestamp: DateTime.now().toUtc(),
          sourceType: PositionSourceType.static,
        ),
        interval: const Duration(seconds: 10),
      );
    }
    await _inner!.start();
  }

  @override
  Future<void> stop() async => _inner?.stop();
}

/// Lazy-resolved [TLESource] that initialises its [TleManager] asynchronously
/// on first [start] so the provider can be constructed synchronously.
class _DeferredTleSource implements PositionSource {
  TLESource? _inner;

  Future<TLESource> _resolve() async {
    if (_inner != null) return _inner!;
    final docsDir = await getApplicationDocumentsDirectory();
    _inner = TLESource(
      manager: TleManager.create(docsDir),
      bridge: BridgeController(),
    );
    return _inner!;
  }

  @override
  PositionSourceType get type => PositionSourceType.estimated;

  @override
  Stream<OrbitalPosition> get positionStream =>
      _inner?.positionStream ?? const Stream.empty();

  @override
  Future<void> start() async => (await _resolve()).start();

  @override
  Future<void> stop() async => _inner?.stop();
}

// ── Source registry ───────────────────────────────────────────────────────

/// Static metadata describing a position source: what it is, where it sits in
/// the automatic fallback priority order, and how it is constructed.
///
/// This is the single place to register a new telemetry source. To add a new
/// API, WebSocket feed, or geocoded-address source, implement [PositionSource]
/// and add one [PositionSourceDescriptor] here — the controller, settings
/// toggles, and override UI all derive from this list.
class PositionSourceDescriptor {
  const PositionSourceDescriptor({
    required this.type,
    required this.label,
    required this.priority,
    required this.requiresNetwork,
    required this.defaultEnabled,
    required this.provider,
    required this.staleTimeout,
    required this.breakerBuilder,
  });

  /// The source type this descriptor configures.
  final PositionSourceType type;

  /// Short label shown in settings / the HUD (e.g. "ISS LIVE", "TLE").
  final String label;

  /// Fallback priority — lower wins. The controller prefers the lowest-priority
  /// enabled source that is healthy.
  final int priority;

  /// Whether the source depends on live connectivity. Network sources back off
  /// aggressively (exponential) when they fail; local sources re-probe flatly.
  final bool requiresNetwork;

  /// Whether the source participates in the fallback chain on a fresh install.
  final bool defaultEnabled;

  /// Riverpod provider yielding a [PositionSource] instance. Overridable in
  /// tests via `overrideWithValue`.
  final ProviderListenable<PositionSource> provider;

  /// How long the controller waits without a fresh fix before declaring this
  /// source stale and demoting to the next enabled source.
  final Duration staleTimeout;

  /// Builds the [CircuitBreaker] that schedules recovery probes for this source.
  final CircuitBreaker Function() breakerBuilder;
}

/// All registered position sources, ordered by ascending [priority].
///
/// Automatic fallback walks this list (filtered to the enabled set):
/// WhereTheISS.at → CelesTrak TLE → Manual lat/long, with GPS as an optional,
/// default-off extra.
final List<PositionSourceDescriptor> kPositionSourceDescriptors = [
  PositionSourceDescriptor(
    type: PositionSourceType.live,
    label: 'ISS LIVE',
    priority: 0,
    requiresNetwork: true,
    defaultEnabled: true,
    provider: livePositionSourceProvider,
    staleTimeout: const Duration(seconds: 8),
    // Network source: exponential backoff, occasional re-probe.
    breakerBuilder: () => CircuitBreaker(
      cooldown: const Duration(seconds: 30),
      backoffMultiplier: 2,
      maxCooldown: const Duration(minutes: 5),
    ),
  ),
  PositionSourceDescriptor(
    type: PositionSourceType.estimated,
    label: 'TLE',
    priority: 1,
    // Works offline from a cached TLE, so it is not treated as a network
    // source; it still re-probes flatly if it had been demoted (e.g. no TLE
    // cached yet, then a refresh lands).
    requiresNetwork: false,
    defaultEnabled: true,
    provider: tlePositionSourceProvider,
    staleTimeout: const Duration(seconds: 8),
    breakerBuilder: () =>
        CircuitBreaker(cooldown: const Duration(seconds: 15), backoffMultiplier: 1),
  ),
  PositionSourceDescriptor(
    type: PositionSourceType.static,
    label: 'MANUAL',
    priority: 2,
    requiresNetwork: false,
    defaultEnabled: true,
    provider: staticPositionSourceProvider,
    staleTimeout: const Duration(seconds: 20),
    breakerBuilder: () =>
        CircuitBreaker(cooldown: const Duration(seconds: 15), backoffMultiplier: 1),
  ),
  PositionSourceDescriptor(
    type: PositionSourceType.gps,
    label: 'GPS',
    priority: 3,
    requiresNetwork: false,
    defaultEnabled: false,
    provider: gpsPositionSourceProvider,
    staleTimeout: const Duration(seconds: 20),
    breakerBuilder: () =>
        CircuitBreaker(cooldown: const Duration(seconds: 15), backoffMultiplier: 1),
  ),
];

/// Looks up the descriptor for [type], or null if not registered.
PositionSourceDescriptor? descriptorFor(PositionSourceType type) {
  for (final d in kPositionSourceDescriptors) {
    if (d.type == type) return d;
  }
  return null;
}
