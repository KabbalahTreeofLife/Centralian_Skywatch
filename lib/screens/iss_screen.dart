import 'package:flutter/material.dart';

/// ISS tab: live position of the International Space Station.
///
/// The map, readouts and refresh button are implemented in Issue #7.
class IssScreen extends StatelessWidget {
  const IssScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISS Tracker')),
      body: const Center(
        child: Text('Live ISS position will appear here.'),
      ),
    );
  }
}
