import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/launch.dart';
import '../providers/launch_provider.dart';
import '../providers/load_status.dart';
import '../routes/app_routes.dart';
import '../widgets/launch_card.dart';
import '../widgets/load_state_views.dart';

/// Launches tab: the upcoming rocket launches.
///
/// Owns a single one-second timer that rebuilds the list so the countdowns
/// tick. One timer for the whole screen, rather than one per card, keeps the
/// cost flat as the list grows and gives the timer exactly one owner to cancel.
class LaunchesScreen extends StatefulWidget {
  const LaunchesScreen({super.key});

  @override
  State<LaunchesScreen> createState() => _LaunchesScreenState();
}

class _LaunchesScreenState extends State<LaunchesScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LaunchProvider>().load();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LaunchProvider provider = context.watch<LaunchProvider>();
    final ({IconData icon, String? title}) failure = describeFailure(
      provider.error,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Launches')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: switch (provider.status) {
          LoadStatus.idle || LoadStatus.loading => const LoadingView(
            key: ValueKey<String>('launches_loading'),
            message: 'Loading launches.',
          ),
          LoadStatus.error => ErrorRetryView(
            key: const ValueKey<String>('launches_error'),
            icon: failure.icon,
            title: failure.title ?? 'Could not load the launches',
            message: provider.error?.message ?? 'Something went wrong.',
            onRetry: () => provider.load(force: true),
          ),
          LoadStatus.success => _list(provider.data ?? const <Launch>[]),
        },
      ),
    );
  }

  Widget _list(List<Launch> launches) {
    if (launches.isEmpty) {
      return const EmptyStateView(
        icon: Icons.rocket_launch_outlined,
        title: 'No upcoming launches',
        message: 'There are no scheduled launches right now. Check back soon.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<LaunchProvider>().load(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: launches.length,
        itemBuilder: (BuildContext context, int index) {
          final Launch launch = launches[index];
          return LaunchCard(
            launch: launch,
            now: _now,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.launchDetail, arguments: launch),
          );
        },
      ),
    );
  }
}
