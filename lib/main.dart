import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'position/tle_manager.dart';
import 'position/tle_refresh_daemon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  final docsDir = await getApplicationDocumentsDirectory();
  await TleRefreshDaemon.init(TleManager.create(docsDir));

  runApp(
    const ProviderScope(
      child: WhatOnEarthApp(),
    ),
  );
}
