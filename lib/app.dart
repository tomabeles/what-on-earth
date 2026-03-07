import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/ar_screen.dart';
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
      home: const ARScreen(),
    );
  }
}
