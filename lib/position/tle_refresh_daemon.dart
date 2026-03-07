import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';

import 'tle_manager.dart';

/// Registers a `background_fetch` periodic task that refreshes the on-disk
/// TLE every 6 hours (360 minutes), even when the app is in the background.
///
/// Call [TleRefreshDaemon.init] from `main()` after
/// [WidgetsFlutterBinding.ensureInitialized].
///
/// Reference: TECH_SPEC §4.2
class TleRefreshDaemon {
  TleRefreshDaemon._();

  /// Configures the background fetch scheduler and performs an immediate
  /// fetch so the TLE is available as soon as possible after install.
  static Future<void> init(TleManager manager) async {
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 360, // 6 hours in minutes
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ),
        (String taskId) async {
          debugPrint('TleRefreshDaemon: background fetch — taskId=$taskId');
          await manager.fetchAndStore();
          BackgroundFetch.finish(taskId);
        },
        (String taskId) {
          // Timeout callback — finish immediately to avoid being killed.
          debugPrint('TleRefreshDaemon: fetch timed out — taskId=$taskId');
          BackgroundFetch.finish(taskId);
        },
      );

      // Eagerly fetch on first launch so the TLE is ready before
      // TLESource (WOE-011) is needed.
      await manager.fetchAndStore();
    } catch (e) {
      // background_fetch is unsupported on desktop/web; log and continue.
      debugPrint('TleRefreshDaemon.init: $e');
    }
  }
}
