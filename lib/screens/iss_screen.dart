import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/iss_provider.dart';
import '../providers/load_status.dart';

/// ISS tab: live position of the International Space Station.
///
/// Issue #10 wires the provider and shows its status. The map, readouts and
/// refresh button are built in Issue #7.
class IssScreen extends StatefulWidget {
  const IssScreen({super.key});

  @override
  State<IssScreen> createState() => _IssScreenState();
}

class _IssScreenState extends State<IssScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IssProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final IssProvider provider = context.watch<IssProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('ISS Tracker')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _status(provider),
              const SizedBox(height: 24),
              const Text('Live ISS position will appear here.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(IssProvider provider) => switch (provider.status) {
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
      'Loaded: ${provider.data?.latitude.toStringAsFixed(2) ?? '—'}, '
      '${provider.data?.longitude.toStringAsFixed(2) ?? '—'}',
    ),
  };
}
