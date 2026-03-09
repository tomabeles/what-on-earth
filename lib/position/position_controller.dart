import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globe/bridge.dart';
import 'gps_position_source.dart';
import 'iss_live_source.dart';
import 'position_source.dart';
import 'static_position_source.dart';
import 'tle_manager.dart';
import 'tle_source.dart';

part 'position_controller.g.dart';

/// Snapshot of the current position source state for display in the status
/// indicator widget (WOE-015).
class PositionSourceStatus {
  const PositionSourceStatus({
    required this.sourceType,
    required this.isLive,
    this.lastFixAt,
  });

  /// Which data source is currently active.
  final PositionSourceType sourceType;

  /// True when the live API is the active source and producing `live` fixes.
  final bool isLive;

  /// Wall-clock time of the most recent fix, or null before the first fix.
  final DateTime? lastFixAt;

  @override
  String toString() =>
      'PositionSourceStatus(sourceType=$sourceType, isLive=$isLive, '
      'lastFixAt=$lastFixAt)';
}

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

// ── PositionController ────────────────────────────────────────────────────

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
@Riverpod(keepAlive: true)
class PositionController extends _$PositionController {
  static const _kFallbackThreshold = 3;

  final _positionStreamController =
      StreamController<OrbitalPosition>.broadcast();

  /// Broadcast stream that always delivers positions from the active source.
  Stream<OrbitalPosition> get positionStream =>
      _positionStreamController.stream;

  PositionSource? _activeSource;
  StreamSubscription<OrbitalPosition>? _sourceSub;
  int _consecutiveEstimated = 0;
  bool _inFallback = false;
  PositionSourceType? _pinnedMode;

  @override
  Future<PositionSourceStatus> build() async {
    ref.onDispose(() {
      _sourceSub?.cancel();
      _activeSource?.stop();
      _positionStreamController.close();
    });

    final live = ref.read(livePositionSourceProvider);
    await _switchTo(live);

    return const PositionSourceStatus(
      sourceType: PositionSourceType.live,
      isLive: false,
    );
  }

  Future<void> _switchTo(PositionSource source) async {
    await _sourceSub?.cancel();
    await _activeSource?.stop();

    _activeSource = source;
    await source.start();

    _sourceSub = source.positionStream.listen(
      _onPosition,
      onError: (Object e) => debugPrint('PositionController: stream error: $e'),
    );
  }

  void _onPosition(OrbitalPosition pos) {
    if (_positionStreamController.isClosed) return;
    _positionStreamController.add(pos);

    state = AsyncData(PositionSourceStatus(
      sourceType: pos.sourceType,
      isLive: pos.sourceType == PositionSourceType.live,
      lastFixAt: pos.timestamp,
    ));

    if (_pinnedMode != null) return;

    if (!_inFallback) {
      if (pos.sourceType == PositionSourceType.estimated) {
        _consecutiveEstimated++;
        if (_consecutiveEstimated >= _kFallbackThreshold) {
          debugPrint('PositionController: falling back to TLESource');
          _inFallback = true;
          _consecutiveEstimated = 0;
          _switchTo(ref.read(tlePositionSourceProvider));
        }
      } else {
        _consecutiveEstimated = 0;
      }
    } else {
      if (pos.sourceType == PositionSourceType.live) {
        debugPrint('PositionController: live API recovered, switching back');
        _inFallback = false;
        _switchTo(ref.read(livePositionSourceProvider));
      }
    }
  }

  /// Pins the active source to [mode]. Pass null to restore auto-switching.
  Future<void> setSourceMode(PositionSourceType? mode) async {
    _pinnedMode = mode;
    _consecutiveEstimated = 0;
    _inFallback = false;

    if (mode == null || mode == PositionSourceType.live) {
      await _switchTo(ref.read(livePositionSourceProvider));
    } else if (mode == PositionSourceType.estimated) {
      await _switchTo(ref.read(tlePositionSourceProvider));
    } else if (mode == PositionSourceType.static) {
      await _switchTo(ref.read(staticPositionSourceProvider));
    } else if (mode == PositionSourceType.gps) {
      await _switchTo(ref.read(gpsPositionSourceProvider));
    }
  }
}
