import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Launches tab: upcoming rocket launches.
///
/// The real list, countdowns and loading/error states are implemented in
/// Issue #6. The placeholder rows here prove that list -> detail navigation
/// passes data.
class LaunchesScreen extends StatelessWidget {
  const LaunchesScreen({super.key});

  static const List<String> _placeholderLaunches = <String>[
    'Falcon 9 Block 5 | Starlink Group',
    'Ariane 62 | Demo flight',
    'Starship | Flight test',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Launches')),
      body: ListView.separated(
        itemCount: _placeholderLaunches.length,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final String name = _placeholderLaunches[index];
          return ListTile(
            title: Text(name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.launchDetail,
              // TODO(#6): pass the Launch object once the model exists (#3).
              arguments: name,
            ),
          );
        },
      ),
    );
  }
}
