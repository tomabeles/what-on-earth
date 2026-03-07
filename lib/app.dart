import 'package:flutter/material.dart';

import 'screens/ar_screen.dart';
import 'shared/theme.dart';

class WhatOnEarthApp extends StatelessWidget {
  const WhatOnEarthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What On Earth?!',
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(AppThemes.night),
      home: const ARScreen(),
    );
  }
}
