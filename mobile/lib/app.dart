import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class CrossSafeApp extends StatelessWidget {
  const CrossSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrossSafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
