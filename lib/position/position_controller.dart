import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'circuit_breaker.dart';
import 'enabled_sources_provider.dart';
import 'position_source.dart';
import 'position_source_registry.dart';

// Re-export the source registry so existing imports of the source providers
// (livePositionSourceProvider, etc.) keep resolving through this library.
export 'position_source_registry.dart';

part 'position_controller.g.dart';

/// Injectable wall-clock used for watchdog/circuit-breaker timing. Overridden
/// in tests (set before reading [positionControllerProvider]) so fallback and
/// recovery logic is fully deterministic.
@visibleForTesting
DateTime Function() positionNow = DateTime.now;

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

// ── PositionController ────────────────────────────────────────────────────

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
@Riverpod(keepAlive: true)
class PositionController extends _$PositionController {
  /// How often the staleness / recovery watchdog runs.
  static const _kWatchdogTick = Duration(seconds: 1);

  /// How long a recovery probe is given to produce a fix before it is failed.
  @visibleForTesting
  static const kProbeWindow = Duration(seconds: 6);

  final _positionStreamController =
      StreamController<OrbitalPosition>.broadcast();

  /// Broadcast stream that always delivers positions from the active source.
  Stream<OrbitalPosition> get positionStream =>
      _positionStreamController.stream;

  // Enabled set + manual pin define the active chain.
  Set<PositionSourceType> _enabled = const {};
  PositionSourceType? _pinned;

  // Active source state.
  PositionSourceType? _activeType;
  PositionSource? _activeSource;
  StreamSubscription<OrbitalPosition>? _activeSub;
  DateTime? _activeSince;
  DateTime? _lastFixAt;

  // In-flight recovery probe (a higher-priority source being re-tried while the
  // current source keeps running).
  PositionSourceType? _probeType;
  PositionSource? _probeSource;
  StreamSubscription<OrbitalPosition>? _probeSub;
  DateTime? _probeDeadline;

  // Per-source circuit breakers, keyed by type.
  final Map<PositionSourceType, CircuitBreaker> _breakers = {};

  Timer? _watchdog;

  @override
  Future<PositionSourceStatus> build() async {
    _enabled = ref.read(enabledSourcesProvider);
    ref.listen(enabledSourcesProvider, (_, next) => _onEnabledChanged(next));

    for (final d in kPositionSourceDescriptors) {
      _breakers[d.type] = d.breakerBuilder();
    }

    ref.onDispose(() {
      _watchdog?.cancel();
      _activeSub?.cancel();
      _activeSource?.stop();
      _stopProbe();
      _positionStreamController.close();
    });

    await _reevaluate(positionNow());
    _watchdog = Timer.periodic(_kWatchdogTick, (_) => _tick());

    return PositionSourceStatus(
      sourceType: _activeType ?? PositionSourceType.static,
      isLive: false,
    );
  }

  /// Active fallback chain, highest priority first.
  List<PositionSourceType> get _chain {
    if (_pinned != null) return [_pinned!];
    return [
      for (final d in kPositionSourceDescriptors)
        if (_enabled.contains(d.type)) d.type,
    ];
  }

  // ── Activation ─────────────────────────────────────────────────────────

  /// Activates the highest-priority chain source whose breaker is closed,
  /// falling back to the last source as a guaranteed last resort. Sources with
  /// open/half-open breakers are reached via [_maybeProbe] instead.
  Future<void> _reevaluate(DateTime now) async {
    final chain = _chain;
    if (chain.isEmpty) return;

    var target = chain.last; // last resort, even if its breaker is tripped
    for (final t in chain) {
      if ((_breakers[t]?.state(now) ?? BreakerState.closed) ==
          BreakerState.closed) {
        target = t;
        break;
      }
    }
    if (target != _activeType) await _activate(target, now);
  }

  Future<void> _activate(PositionSourceType type, DateTime now) async {
    await _activeSub?.cancel();
    await _activeSource?.stop();

    final desc = descriptorFor(type)!;
    _activeType = type;
    _activeSource = ref.read(desc.provider);
    _activeSince = now;
    _lastFixAt = null;
    await _activeSource!.start();
    _activeSub = _activeSource!.positionStream.listen(
      _onActiveFix,
      onError: (Object e) => debugPrint('PositionController: stream error: $e'),
    );
  }

  void _onActiveFix(OrbitalPosition pos) {
    if (_positionStreamController.isClosed) return;
    _lastFixAt = positionNow();
    _breakers[_activeType]?.recordSuccess();
    _emit(pos);
  }

  void _emit(OrbitalPosition pos) {
    _positionStreamController.add(pos);
    state = AsyncData(PositionSourceStatus(
      sourceType: pos.sourceType,
      isLive: pos.sourceType == PositionSourceType.live,
      lastFixAt: pos.timestamp,
    ));
  }

  // ── Watchdog: staleness demotion + recovery probes ───────────────────────

  /// Manually advances the watchdog. Exposed for deterministic tests; the
  /// periodic timer calls the same logic in production.
  @visibleForTesting
  void tick() => _tick();

  void _tick() {
    final now = positionNow();
    _checkStaleness(now);
    _maybeProbe(now);
    _checkProbeDeadline(now);
  }

  void _checkStaleness(DateTime now) {
    final type = _activeType;
    if (type == null) return;
    final desc = descriptorFor(type)!;
    final since = _lastFixAt ?? _activeSince ?? now;
    if (now.difference(since) < desc.staleTimeout) return;

    if (_pinned != null) {
      // Pinned: keep retrying the forced source without thrashing the chain.
      _activeSince = now;
      return;
    }

    // Active source is stale → trip its breaker and demote.
    _breakers[type]?.recordFailure(now);
    final chain = _chain;
    final idx = chain.indexOf(type);
    if (idx >= 0 && idx + 1 < chain.length) {
      _reevaluate(now);
    } else {
      // Last source in the chain — nothing lower to fall to. Reset the window
      // so we keep retrying it rather than spinning.
      _activeSince = now;
    }
  }

  void _maybeProbe(DateTime now) {
    if (_pinned != null || _probeType != null) return;
    final activeType = _activeType;
    if (activeType == null) return;
    final activePriority = descriptorFor(activeType)!.priority;

    for (final d in kPositionSourceDescriptors) {
      if (!_enabled.contains(d.type)) continue;
      if (d.priority >= activePriority) continue; // only higher priority
      if (_breakers[d.type]?.shouldProbe(now) ?? false) {
        _startProbe(d.type, now);
        break;
      }
    }
  }

  Future<void> _startProbe(PositionSourceType type, DateTime now) async {
    _probeType = type;
    _probeDeadline = now.add(kProbeWindow);
    final desc = descriptorFor(type)!;
    _probeSource = ref.read(desc.provider);
    await _probeSource!.start();
    _probeSub = _probeSource!.positionStream.listen(
      (pos) => _onProbeFix(type, pos),
      onError: (Object e) => debugPrint('PositionController: probe error: $e'),
    );
  }

  void _onProbeFix(PositionSourceType type, OrbitalPosition pos) {
    if (_probeType != type || _positionStreamController.isClosed) return;
    // Probe produced a fix → promote it to the active source.
    _breakers[type]?.recordSuccess();

    final promoted = _probeSource!;
    final promotedSub = _probeSub!;
    _probeType = null;
    _probeSource = null;
    _probeSub = null;
    _probeDeadline = null;

    // Stop the (lower-priority) current source and adopt the probe.
    _activeSub?.cancel();
    _activeSource?.stop();
    _activeType = type;
    _activeSource = promoted;
    _activeSub = promotedSub..onData((p) => _onActiveFix(p));
    _activeSince = positionNow();
    _lastFixAt = positionNow();
    _emit(pos);
  }

  void _checkProbeDeadline(DateTime now) {
    final deadline = _probeDeadline;
    if (_probeType == null || deadline == null) return;
    if (now.isBefore(deadline)) return;
    // Probe timed out → fail it (escalates backoff) and stop the probe source.
    _breakers[_probeType]?.recordFailure(now);
    _stopProbe();
  }

  void _stopProbe() {
    _probeSub?.cancel();
    _probeSource?.stop();
    _probeType = null;
    _probeSource = null;
    _probeSub = null;
    _probeDeadline = null;
  }

  // ── Settings reactions ───────────────────────────────────────────────────

  void _onEnabledChanged(Set<PositionSourceType> next) {
    _enabled = next;
    if (_pinned != null) return; // pin overrides the enabled chain
    // If a probe targets a now-disabled source, abandon it.
    if (_probeType != null && !next.contains(_probeType)) _stopProbe();
    _reevaluate(positionNow());
  }

  /// Pins the active source to [mode]. Pass null to restore auto-switching.
  Future<void> setSourceMode(PositionSourceType? mode) async {
    _stopProbe();
    _pinned = mode;
    // Reset breakers so a fresh AUTO run / new pin starts clean.
    for (final b in _breakers.values) {
      b.recordSuccess();
    }
    final now = positionNow();
    if (mode != null) {
      await _activate(mode, now);
    } else {
      // Force re-activation from the top of the restored chain.
      _activeType = null;
      await _reevaluate(now);
    }
  }
}
