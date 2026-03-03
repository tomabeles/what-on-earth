import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(
    const ProviderScope(
      child: WhatOnEarthApp(),
    ),
  );
}
