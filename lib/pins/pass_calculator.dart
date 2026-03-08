import 'dart:async';

import 'package:uuid/uuid.dart';

import '../globe/bridge.dart';

const _uuid = Uuid();

/// Wraps the REQUEST_PASS_CALC / PASS_CALC_RESULT bridge round-trip
/// in a Future-based API (TECH_SPEC §7.4).
class PassCalculator {
  final BridgeController _bridge;
  final _pending = <String, Completer<PassCalcResponse>>{};
  StreamSubscription<PassCalcResponse>? _sub;

  PassCalculator(this._bridge) {
    _sub = _bridge.passCalcResults.listen(_onResult);
  }

  void _onResult(PassCalcResponse response) {
    final completer = _pending.remove(response.requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }
  }

  /// Calculate the next overhead pass for the given location.
  /// Returns null if no TLE is loaded or calculation times out.
  Future<PassCalcResponse?> calculateNextPass(double lat, double lon) async {
    final requestId = _uuid.v4();
    final completer = Completer<PassCalcResponse>();
    _pending[requestId] = completer;

    await _bridge.requestPassCalc(requestId, lat, lon);

    try {
      return await completer.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _pending.remove(requestId);
      return null;
    }
  }

  void dispose() {
    _sub?.cancel();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('disposed'));
    }
    _pending.clear();
  }
}
