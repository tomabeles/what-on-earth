import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/circuit_breaker.dart';

void main() {
  final t0 = DateTime.utc(2024, 1, 1);

  group('CircuitBreaker', () {
    test('starts closed', () {
      final b = CircuitBreaker();
      expect(b.state(t0), BreakerState.closed);
      expect(b.shouldProbe(t0), isFalse);
    });

    test('opens on failure and stays open during the cooldown', () {
      final b = CircuitBreaker(cooldown: const Duration(seconds: 30));
      b.recordFailure(t0);
      expect(b.state(t0), BreakerState.open);
      // Still within cooldown.
      expect(b.shouldProbe(t0.add(const Duration(seconds: 29))), isFalse);
    });

    test('half-opens (shouldProbe) once the cooldown elapses', () {
      final b = CircuitBreaker(cooldown: const Duration(seconds: 30));
      b.recordFailure(t0);
      expect(b.shouldProbe(t0.add(const Duration(seconds: 30))), isTrue);
      expect(b.state(t0.add(const Duration(seconds: 30))), BreakerState.halfOpen);
    });

    test('success resets to closed and clears backoff', () {
      final b = CircuitBreaker(cooldown: const Duration(seconds: 30));
      b.recordFailure(t0);
      b.recordSuccess();
      expect(b.state(t0), BreakerState.closed);
      expect(b.shouldProbe(t0.add(const Duration(hours: 1))), isFalse);
    });

    test('escalates the cooldown with exponential backoff up to maxCooldown',
        () {
      final b = CircuitBreaker(
        cooldown: const Duration(seconds: 30),
        backoffMultiplier: 2,
        maxCooldown: const Duration(minutes: 2),
      );

      // First failure → 30s cooldown.
      b.recordFailure(t0);
      expect(b.shouldProbe(t0.add(const Duration(seconds: 29))), isFalse);
      expect(b.shouldProbe(t0.add(const Duration(seconds: 30))), isTrue);

      // Failed probe → 60s cooldown.
      final t1 = t0.add(const Duration(seconds: 30));
      b.recordFailure(t1);
      expect(b.shouldProbe(t1.add(const Duration(seconds: 59))), isFalse);
      expect(b.shouldProbe(t1.add(const Duration(seconds: 60))), isTrue);

      // Failed probe → would be 120s; capped at maxCooldown (120s).
      final t2 = t1.add(const Duration(seconds: 60));
      b.recordFailure(t2);
      expect(b.shouldProbe(t2.add(const Duration(seconds: 119))), isFalse);
      expect(b.shouldProbe(t2.add(const Duration(seconds: 120))), isTrue);

      // Still capped at 120s, not 240s.
      final t3 = t2.add(const Duration(seconds: 120));
      b.recordFailure(t3);
      expect(b.shouldProbe(t3.add(const Duration(seconds: 120))), isTrue);
    });

    test('flat (multiplier 1) cooldown does not escalate', () {
      final b = CircuitBreaker(
        cooldown: const Duration(seconds: 15),
        backoffMultiplier: 1,
      );
      b.recordFailure(t0);
      final t1 = t0.add(const Duration(seconds: 15));
      b.recordFailure(t1);
      expect(b.shouldProbe(t1.add(const Duration(seconds: 14))), isFalse);
      expect(b.shouldProbe(t1.add(const Duration(seconds: 15))), isTrue);
    });
  });
}
