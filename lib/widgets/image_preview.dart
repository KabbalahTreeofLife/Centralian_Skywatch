import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens a dismissible, zoomable view of a network image.
Future<void> showImagePreview(
  BuildContext context, {
  required String url,
  required String semanticLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (BuildContext context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: <Widget>[
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
                maxWidth: MediaQuery.sizeOf(context).width * 0.94,
              ),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                imageBuilder:
                    (BuildContext context, ImageProvider<Object> image) =>
                        Semantics(
                          label: semanticLabel,
                          image: true,
                          child: Image(image: image, fit: BoxFit.contain),
                        ),
                placeholder: (BuildContext context, String url) => const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white70,
                    size: 48,
                  ),
                ),
                errorWidget: (BuildContext context, String url, Object error) =>
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close image',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}
