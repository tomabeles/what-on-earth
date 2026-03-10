import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/ar_screen.dart';
import 'screens/loading_screen.dart';
import 'shared/theme.dart';
import 'shared/theme_provider.dart';

class WhatOnEarthApp extends ConsumerWidget {
  const WhatOnEarthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    return MaterialApp(
      title: 'What On Earth?!',
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(appTheme),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final _loadingKey = GlobalKey<LoadingScreenState>();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initAndTransition();
  }

  Future<void> _initAndTransition() async {
    // Show the loading screen for a minimum duration so the animation
    // is visible, then fade out and switch to the AR view.
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await _loadingKey.currentState?.fadeOut();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const ARScreen();
    return LoadingScreen(key: _loadingKey);
  }
}
