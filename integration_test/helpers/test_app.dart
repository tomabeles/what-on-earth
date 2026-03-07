import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/app.dart';

/// Pumps [WhatOnEarthApp] inside a [ProviderScope] for integration tests.
///
/// Provider overrides are added here as live sources (ISSLiveSource, TLESource)
/// are introduced in later tickets. Currently the app uses [StaticPositionSource]
/// directly in [ARScreen], so no overrides are needed yet.
Future<void> pumpTestApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: WhatOnEarthApp(),
    ),
  );
}
