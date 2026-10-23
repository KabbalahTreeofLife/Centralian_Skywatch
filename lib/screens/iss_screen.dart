import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/iss_position.dart';
import '../providers/iss_provider.dart';
import '../providers/load_status.dart';
import '../widgets/iss_map.dart';
import '../widgets/iss_readouts.dart';
import '../widgets/load_state_views.dart';

/// ISS tab: where the station is right now.
///
/// Refreshes on its own every [refreshInterval] so the position stays live
/// without the user having to ask. Those ticks are silent, so the map and
/// readouts update in place instead of flashing a loading view; only the
/// refresh button shows one. The timer is cancelled in [dispose], and every
/// tick checks `mounted` first.
class IssScreen extends StatefulWidget {
  const IssScreen({super.key});

  /// How often to re-fetch the position.
  ///
  /// The station orbits in about 90 minutes, so a few seconds either way makes
  /// no visible difference; 15s keeps it feeling live without hammering a free
  /// API.
  static const Duration refreshInterval = Duration(seconds: 15);

  @override
  State<IssScreen> createState() => _IssScreenState();
}

class _IssScreenState extends State<IssScreen> {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IssProvider>().load();
    });
    _autoRefresh = Timer.periodic(IssScreen.refreshInterval, (_) {
      if (!mounted) return;
      // Silent: the position updates in place. Only the refresh button is
      // allowed to replace the screen with a loading view.
      context.read<IssProvider>().load(force: true, silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IssProvider provider = context.watch<IssProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISS Tracker'),
        actions: <Widget>[
          IconButton(
            onPressed: provider.status == LoadStatus.loading
                ? null
                : () => provider.load(force: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh position',
          ),
        ],
      ),
      body: switch (provider.status) {
        LoadStatus.idle || LoadStatus.loading => const LoadingView(
          message: 'Locating the station…',
        ),
        LoadStatus.error => ErrorRetryView(
          message: provider.error?.message ?? 'Something went wrong.',
          onRetry: () => provider.load(force: true),
        ),
        LoadStatus.success => _tracker(provider.data),
      },
    );
  }

  Widget _tracker(IssPosition? position) {
    if (position == null) {
      return const EmptyStateView(
        icon: Icons.satellite_alt_outlined,
        title: 'No position available',
        message: 'The station did not report a position. Try refreshing.',
      );
    }

    return Column(
      children: <Widget>[
        Expanded(child: IssMap(position: position)),
        const Divider(height: 1),
        IssReadouts(position: position),
        if (position.timestamp case final DateTime timestamp)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Updated ${_formatTime(timestamp.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// `14:32:07`, in the device's own zone.
  static String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    final String second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
