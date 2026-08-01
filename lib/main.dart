import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const PiBallApp());
}

class PiBallApp extends StatelessWidget {
  const PiBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiBall',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
