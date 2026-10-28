import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Shows a playable APOD video in a modal player.
Future<void> showApodVideoPlayer(
  BuildContext context, {
  required String url,
  required String title,
  String? fallbackUrl,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (BuildContext context) =>
        _ApodVideoDialog(url: url, title: title, fallbackUrl: fallbackUrl),
  );
}

class _ApodVideoDialog extends StatefulWidget {
  const _ApodVideoDialog({
    required this.url,
    required this.title,
    required this.fallbackUrl,
  });

  final String url;
  final String title;
  final String? fallbackUrl;

  @override
  State<_ApodVideoDialog> createState() => _ApodVideoDialogState();
}

class _ApodVideoDialogState extends State<_ApodVideoDialog> {
  late final VideoPlayerController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('APOD video initialization failed: $error');
      if (!mounted) return;
      setState(
        () => _error = 'The video could not be loaded. Please try again.',
      );
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_controller.value.isPlaying) {
        await _controller.pause();
      } else {
        await _controller.play();
      }
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('APOD video playback failed: $error');
      if (mounted) {
        setState(
          () =>
              _error = 'Playback failed. Please try opening the video on NASA.',
        );
      }
    }
  }

  Future<void> _openFallback() async {
    final String? fallback = widget.fallbackUrl;
    final Uri? uri = fallback == null ? null : Uri.tryParse(fallback);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not open the APOD video page.');
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close video',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_error case final String error)
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error, textAlign: TextAlign.center),
                    ),
                    if (widget.fallbackUrl != null)
                      TextButton.icon(
                        onPressed: _openFallback,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open on NASA'),
                      ),
                  ],
                )
              else if (!_controller.value.isInitialized)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...<Widget>[
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                IconButton.filledTonal(
                  onPressed: _togglePlayback,
                  tooltip: _controller.value.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
