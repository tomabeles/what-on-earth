/// Circuit-breaker states for a fallible position source.
enum BreakerState {
  /// Source is considered healthy; the controller may run it normally.
  closed,

  /// Source has failed; the controller has demoted away from it and will not
  /// probe again until the cooldown elapses.
  open,

  /// Cooldown has elapsed; the controller may run a single recovery probe.
  halfOpen,
}

/// Tracks the health of a single [PositionSource] and schedules occasional
/// recovery probes after failures, with exponential backoff.
///
/// This is the mechanism behind "retry WhereTheISS.at occasionally": when the
/// live API fails repeatedly the breaker trips [BreakerState.open] and the
/// controller stops hammering it, only re-probing once each cooldown window.
/// Each consecutive failure multiplies the cooldown by [backoffMultiplier] up
/// to [maxCooldown]; a single success resets everything to [BreakerState.closed].
///
/// Time is injected via the `now` parameters so the breaker is fully
/// deterministic and unit-testable without timers.
///
/// Reference: TECH_SPEC §7.1
class CircuitBreaker {
  CircuitBreaker({
    this.cooldown = const Duration(seconds: 30),
    this.backoffMultiplier = 2,
    this.maxCooldown = const Duration(minutes: 5),
  })  : assert(backoffMultiplier >= 1),
        _currentCooldown = cooldown;

  /// Base cooldown applied after the first failure.
  final Duration cooldown;

  /// Multiplier applied to the cooldown on each consecutive failure. Use `1`
  /// for a flat (non-escalating) re-probe interval.
  final int backoffMultiplier;

  /// Upper bound on the backed-off cooldown.
  final Duration maxCooldown;

  BreakerState _state = BreakerState.closed;
  Duration _currentCooldown;
  DateTime? _nextProbeAt;

  /// Current state, advancing [BreakerState.open] → [BreakerState.halfOpen]
  /// once the cooldown has elapsed at [now].
  BreakerState state([DateTime? now]) {
    if (_state == BreakerState.open && now != null && _cooldownElapsed(now)) {
      _state = BreakerState.halfOpen;
    }
    return _state;
  }

  /// True when the breaker is open and the cooldown has elapsed, so the caller
  /// should attempt a single recovery probe.
  bool shouldProbe(DateTime now) => state(now) == BreakerState.halfOpen;

  /// Records a successful fix: resets to [BreakerState.closed] and clears any
  /// accumulated backoff.
  void recordSuccess() {
    _state = BreakerState.closed;
    _currentCooldown = cooldown;
    _nextProbeAt = null;
  }

  /// Records a failure (initial trip or a failed probe): opens the breaker and
  /// schedules the next probe, escalating the cooldown via [backoffMultiplier].
  void recordFailure(DateTime now) {
    if (_state != BreakerState.closed) {
      // A repeated failure or a failed recovery probe (the breaker was open or
      // half-open): escalate the backoff.
      final escalated = _currentCooldown * backoffMultiplier;
      _currentCooldown = escalated > maxCooldown ? maxCooldown : escalated;
    }
    _state = BreakerState.open;
    _nextProbeAt = now.add(_currentCooldown);
  }

  bool _cooldownElapsed(DateTime now) {
    final next = _nextProbeAt;
    return next == null || !now.isBefore(next);
  }
}
