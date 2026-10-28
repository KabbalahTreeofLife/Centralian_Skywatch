import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_item.dart';
import '../models/launch.dart';
import '../providers/favorites_provider.dart';
import '../utils/countdown.dart';
import '../utils/date_format.dart';
import 'favorite_feedback.dart';
import 'image_preview.dart';
import 'launch_image.dart';

/// One upcoming launch, as a tappable card.
///
/// The rocket photo is the card's header rather than a thumbnail: it fills a
/// 16:9 banner with the status and the favorite toggle laid over it, and the
/// mission details sit beneath on the card surface. The countdown is recomputed
/// from [now] on every build, so the screen only has to rebuild this card once
/// a second rather than the card owning a timer of its own.
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

  /// Height of the photo banner at the top of the card.
  static const double _bannerHeight = 160;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                // A fixed banner height rather than the image's own 16:9: in a
                // scrolling list the card should stay a predictable size, and
                // a full-width 16:9 box would be taller than the content it
                // introduces.
                SizedBox(
                  height: _bannerHeight,
                  width: double.infinity,
                  child: Hero(
                    tag: 'launch-hero-${launch.id}',
                    child: GestureDetector(
                      onTap: launch.imageUrl == null
                          ? null
                          : () => showImagePreview(
                              context,
                              url: launch.imageUrl!,
                              semanticLabel: 'Rocket for ${launch.name}',
                            ),
                      child: LaunchImage(
                        url: launch.imageUrl,
                        semanticLabel: 'Rocket for ${launch.name}',
                      ),
                    ),
                  ),
                ),
                // Scrim: the chips sit on the photo, so they need a base.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            scheme.surface.withValues(alpha: 0.55),
                            Colors.transparent,
                            scheme.surface.withValues(alpha: 0.35),
                          ],
                          stops: const <double>[0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _StatusChip(status: launch.statusName),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _FavoriteToggle(launch: launch),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Timing(launch: launch, now: now),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether [status] is the positive "Go for Launch" status.
///
/// Matched by name rather than by searching for "go" inside the text, which
/// would also match a negative status such as "No-Go".
@visibleForTesting
bool isGoForLaunch(String status) =>
    status.trim().toLowerCase() == 'go for launch';

/// The launch status, tinted by how close it is to flying.
///
/// It is drawn over a photograph, so it carries its own opaque background
/// instead of relying on the surface behind it.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool go = isGoForLaunch(status);

    final Color background = go
        ? scheme.primary
        : scheme.surface.withValues(alpha: 0.92);
    final Color foreground = go ? scheme.onPrimary : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
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
    final ColorScheme scheme = theme.colorScheme;
    final DateTime? net = launch.net;

    if (net == null) {
      return Text(
        'Launch time to be announced',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final bool counting = isWithinCountdownWindow(net, now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: counting ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            counting ? Icons.timer_outlined : Icons.event_outlined,
            size: 16,
            color: counting
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            counting ? formatCountdown(net, now) : formatDate(net.toLocal()),
            style: theme.textTheme.labelLarge?.copyWith(
              color: counting
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final bool ok = await favorites.toggle(
          FavoriteItem(
            id: launch.id,
            type: FavoriteType.launch,
            title: launch.name,
            data: launch.toJson(),
          ),
        );
        if (!ok) showFavoriteSaveError(messenger);
      },
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        foregroundColor: saved ? scheme.primary : scheme.onSurfaceVariant,
      ),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      tooltip: saved ? 'Remove from favorites' : 'Save to favorites',
    );
  }
}
