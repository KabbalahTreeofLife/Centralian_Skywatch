import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/apod_provider.dart';
import '../providers/load_status.dart';

/// Home tab: NASA's Astronomy Picture of the Day.
///
/// Issue #10 wires the provider and shows its status. The real APOD layout and
/// its loading/error/no-internet states are built in Issue #5.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred so the provider's first notifyListeners() does not run during
    // build. The provider itself ignores repeat calls, so this is safe even if
    // the screen is rebuilt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ApodProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ApodProvider provider = context.watch<ApodProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Today in Space')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _status(provider),
              const SizedBox(height: 24),
              const Text('Astronomy Picture of the Day will appear here.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(ApodProvider provider) => switch (provider.status) {
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
    LoadStatus.success => Text('Loaded: ${provider.data?.title ?? '—'}'),
  };
}
