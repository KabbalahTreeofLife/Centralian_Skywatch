import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The rocket photo for a launch, cached on disk so reopening a launch does not
/// re-download it.
///
/// The placeholder and error states are static on purpose: an animated
/// placeholder would keep the widget tree busy forever, which makes
/// `pumpAndSettle` hang in widget tests. The height is fixed so the layout does
/// not jump between the placeholder, the image and the error state.
class LaunchImage extends StatelessWidget {
  const LaunchImage({
    super.key,
    required this.url,
    required this.semanticLabel,
  });

  /// The image URL, or null when the API did not provide one.
  final String? url;

  /// Describes the picture for screen readers.
  final String semanticLabel;

  /// 16:9, the shape most of the launch photos are published in.
  static const double _aspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final String? url = this.url;

    if (url == null) {
      return const _ImageFrame(child: _RocketPlaceholder());
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (BuildContext context, String url) =>
          const _ImageFrame(child: Icon(Icons.image_outlined, size: 48)),
      errorWidget: (BuildContext context, String url, Object error) =>
          const _ImageFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.broken_image_outlined, size: 48),
                SizedBox(height: 8),
                Text('Image unavailable'),
              ],
            ),
          ),
      imageBuilder: (BuildContext context, ImageProvider<Object> provider) =>
          Semantics(
            label: semanticLabel,
            image: true,
            child: Image(image: provider, fit: BoxFit.cover),
          ),
    );
  }
}

/// Shown when the API did not provide an image for this launch.
class _RocketPlaceholder extends StatelessWidget {
  const _RocketPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.rocket_launch_outlined, size: 48),
        SizedBox(height: 8),
        Text('No image for this launch'),
      ],
    );
  }
}

/// Fixed-aspect box so the layout does not jump between states.
class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: LaunchImage._aspectRatio,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: IconTheme(
          data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
