import 'package:flutter/material.dart';

/// Home tab: NASA's Astronomy Picture of the Day.
///
/// The APOD content and its loading/error/no-internet states are implemented
/// in Issue #5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today in Space')),
      body: const Center(
        child: Text('Astronomy Picture of the Day will appear here.'),
      ),
    );
  }
}
