import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CentralianSkywatchApp());
}

class CentralianSkywatchApp extends StatelessWidget {
  const CentralianSkywatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centralian Skywatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('Centralian Skywatch')),
      ),
    );
  }
}