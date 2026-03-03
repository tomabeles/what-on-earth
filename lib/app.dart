import 'package:flutter/material.dart';

import 'globe/globe_view.dart';

class WhatOnEarthApp extends StatelessWidget {
  const WhatOnEarthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What On Earth?!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: GlobeView(),
      ),
    );
  }
}
