import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_item.dart';
import '../models/launch.dart';
import '../providers/favorites_provider.dart';
import '../utils/countdown.dart';
import '../utils/date_format.dart';
import '../widgets/favorite_feedback.dart';
import '../widgets/launch_image.dart';

/// Detail screen pushed on top of the shell.
///
/// It makes no request of its own: the [Launch] is passed in as the route
/// argument, so opening a card is instant and works offline once the list has
/// loaded.
class LaunchDetailScreen extends StatefulWidget {
  const LaunchDetailScreen({super.key});

  @override
  State<LaunchDetailScreen> createState() => _LaunchDetailScreenState();
}

class _LaunchDetailScreenState extends State<LaunchDetailScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
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
    final Object? argument = ModalRoute.of(context)?.settings.arguments;

    if (argument is! Launch) {
      return Scaffold(
        appBar: AppBar(title: const Text('Launch Detail')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No launch was passed to this screen.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _Detail(launch: argument, now: _now),
    );
  }
}

/// The launch's full details, under a collapsing photo header.
class _Detail extends StatelessWidget {
  const _Detail({required this.launch, required this.now});

  final Launch launch;
  final DateTime now;

  /// How tall the photo is before it collapses into the bar.
  static const double _heroHeight = 300;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final DateTime? net = launch.net;

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          expandedHeight: _heroHeight,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text('Launch Detail'),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Hero(
                  tag: 'launch-hero-${launch.id}',
                  child: LaunchImage(
                    url: launch.imageUrl,
                    semanticLabel: 'Rocket for ${launch.name}',
                  ),
                ),
                // Top scrim: keeps the bar title legible over the photo.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: <Color>[
                        scheme.surface.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Bottom scrim: blends the photo into the content below.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        scheme.surface.withValues(alpha: 0.9),
                        scheme.surface,
                      ],
                      stops: const <double>[0, 0.75, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList.list(
            children: <Widget>[
              Text(launch.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                launch.agency,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (net != null) ...<Widget>[
                _CountdownBanner(net: net, now: now),
                const SizedBox(height: 16),
              ],
              _FavoriteButton(launch: launch),
              const SizedBox(height: 24),
              _DetailGroup(
                rows: <Widget>[
                  _DetailRow(
                    icon: Icons.business_outlined,
                    label: 'Agency',
                    value: launch.agency,
                  ),
                  _DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Launch site',
                    value: launch.locationName,
                  ),
                  _DetailRow(
                    icon: Icons.rocket_launch_outlined,
                    label: 'Pad',
                    value: launch.padName,
                  ),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: 'Status',
                    value: launch.statusDescription.isEmpty
                        ? launch.statusName
                        : '${launch.statusName} — ${launch.statusDescription}',
                  ),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Mission type',
                    value: launch.missionType,
                  ),
                  _DetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'Launch time',
                    value: net == null ? 'To be announced' : _exactTime(net),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The scheduled time in the device's own zone, with UTC alongside it.
  ///
  /// The API publishes `net` in UTC, so showing only the local time would hide
  /// which zone the schedule is actually quoted in.
  static String _exactTime(DateTime net) {
    final DateTime local = net.toLocal();
    final String time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    final String utc =
        '${net.hour.toString().padLeft(2, '0')}:'
        '${net.minute.toString().padLeft(2, '0')} UTC';

    return '${formatDate(local)} at $time\n$utc';
  }
}

/// The live countdown, given its own emphasis.
class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.net, required this.now});

  final DateTime net;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool counting = isWithinCountdownWindow(net, now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer,
            scheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            counting ? 'Launching in' : 'Scheduled for',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            counting ? formatCountdown(net, now) : formatDate(net.toLocal()),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The detail rows, grouped into one bordered card.
class _DetailGroup extends StatelessWidget {
  const _DetailGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// One labelled detail, with an icon.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Saves or unsaves this launch, reflecting the shared favorites state.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.launch});

  final Launch launch;

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider favorites = context.watch<FavoritesProvider>();
    final bool saved = favorites.contains(FavoriteType.launch, launch.id);

    return FilledButton.tonalIcon(
      onPressed: () async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final bool ok = await favorites.toggle(
          FavoriteItem(
            id: launch.id,
            type: FavoriteType.launch,
            title: launch.name,
          ),
        );
        if (!ok) showFavoriteSaveError(messenger);
      },
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      label: Text(saved ? 'Saved to favorites' : 'Save to favorites'),
    );
  }
}
