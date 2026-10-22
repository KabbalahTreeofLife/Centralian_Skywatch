import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_item.dart';
import '../models/launch.dart';
import '../providers/favorites_provider.dart';
import '../utils/countdown.dart';
import '../utils/date_format.dart';

/// One upcoming launch, as a tappable card.
///
/// Shows the mission name, agency, status, a thumbnail and — when the launch is
/// close enough — a live T-minus countdown. The countdown is recomputed from
/// [now] on every build, so the screen only has to rebuild this card once a
/// second rather than the card owning a timer of its own.
class LaunchCard extends StatelessWidget {
  const LaunchCard({
    super.key,
    required this.launch,
    required this.now,
    this.onTap,
  });

  final Launch launch;

  /// The current time, supplied by the screen so every card agrees.
  final DateTime now;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Thumbnail(url: launch.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      launch.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      launch.agency,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(status: launch.statusName),
                    const SizedBox(height: 8),
                    _Timing(launch: launch, now: now),
                  ],
                ),
              ),
              _FavoriteToggle(launch: launch),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mission patch or rocket image, or a placeholder when there is none.
///
/// The API leaves `image` null for many launches, so the placeholder is the
/// common case rather than an edge case.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? url = this.url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _size,
        height: _size,
        child: url == null
            ? Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.rocket_launch_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.rocket_launch_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}

/// The launch status, tinted by how close it is to flying.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool go = status.toLowerCase().contains('go');

    final Color background = go
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final Color foreground = go
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

/// The countdown when the launch is near, otherwise the scheduled date.
class _Timing extends StatelessWidget {
  const _Timing({required this.launch, required this.now});

  final Launch launch;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? net = launch.net;

    if (net == null) {
      return Text(
        'Launch time to be announced',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final bool counting = isWithinCountdownWindow(net, now);

    return Row(
      children: <Widget>[
        Icon(
          counting ? Icons.timer_outlined : Icons.event_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          counting ? formatCountdown(net, now) : formatDate(net.toLocal()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Saves or unsaves this launch, reflecting the shared favorites state.
class _FavoriteToggle extends StatelessWidget {
  const _FavoriteToggle({required this.launch});

  final Launch launch;

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider favorites = context.watch<FavoritesProvider>();
    final bool saved = favorites.contains(FavoriteType.launch, launch.id);

    return IconButton(
      onPressed: () => favorites.toggle(
        FavoriteItem(
          id: launch.id,
          type: FavoriteType.launch,
          title: launch.name,
        ),
      ),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      color: saved ? Theme.of(context).colorScheme.primary : null,
      tooltip: saved ? 'Remove from favorites' : 'Save to favorites',
    );
  }
}
