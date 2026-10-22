import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/launch_provider.dart';
import '../providers/load_status.dart';
import '../routes/app_routes.dart';

/// Launches tab: upcoming rocket launches.
///
/// Issue #10 wires the provider and shows its status. The real list, countdowns
/// and loading/error states are built in Issue #6. The placeholder rows below
/// still prove that list -> detail navigation passes data.
class LaunchesScreen extends StatefulWidget {
  const LaunchesScreen({super.key});

  @override
  State<LaunchesScreen> createState() => _LaunchesScreenState();
}

class _LaunchesScreenState extends State<LaunchesScreen> {
  static const List<String> _placeholderLaunches = <String>[
    'Falcon 9 Block 5 | Starlink Group',
    'Ariane 62 | Demo flight',
    'Starship | Flight test',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LaunchProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final LaunchProvider provider = context.watch<LaunchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Launches')),
      body: Column(
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(16), child: _status(provider)),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
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
                    // TODO(#6): pass the Launch object once the list is real.
                    arguments: name,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(LaunchProvider provider) => switch (provider.status) {
    LoadStatus.idle || LoadStatus.loading => const Text('Loading…'),
    LoadStatus.error => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          provider.error?.message ?? 'Something went wrong.',
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: () => provider.load(force: true),
          child: const Text('Retry'),
        ),
      ],
    ),
    LoadStatus.success => Text(
      'Loaded: ${provider.data?.length ?? 0} launches',
    ),
  };
}
