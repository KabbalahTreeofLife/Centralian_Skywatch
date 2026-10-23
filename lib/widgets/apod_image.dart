import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The APOD picture, cached on disk so revisiting the tab does not re-download.
///
/// The placeholder and error states are static on purpose: an animated
/// placeholder would keep the widget tree busy forever, which makes
/// `pumpAndSettle` hang in widget tests.
class ApodImage extends StatelessWidget {
  const ApodImage({required this.url, required this.semanticLabel, super.key});

  final String url;

  /// Describes the picture for screen readers.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
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

/// Backdrop for the placeholder and error states.
///
/// It carries no height of its own: the picture is always laid out inside a
/// sized hero, so the frame simply fills whatever box it is given and the
/// layout does not jump between the placeholder, the image and the error state.
class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
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
    );
  }
}
