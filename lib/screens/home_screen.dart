import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/apod.dart';
import '../models/favorite_item.dart';
import '../providers/apod_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/load_status.dart';
import '../services/api_exception.dart';
import '../utils/date_format.dart';
import '../widgets/apod_image.dart';

/// Home tab: NASA's Astronomy Picture of the Day.
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
      body: switch (provider.status) {
        LoadStatus.idle || LoadStatus.loading => const _LoadingState(),
        LoadStatus.error => _ErrorState(
          error: provider.error,
          onRetry: () => provider.load(force: true),
        ),
        LoadStatus.success => _ApodView(apod: provider.data!),
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading today\'s picture…'),
      ],
    ),
  );
}

/// Shown when the request failed, with a message tailored to the failure.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final ApiException? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool offline = error is NoInternetException;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              offline ? Icons.wifi_off : Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              offline ? 'You are offline' : 'Could not load the picture',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error?.message ?? 'Something went wrong. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The loaded picture, its details and the favorite button.
class _ApodView extends StatelessWidget {
  const _ApodView({required this.apod});

  final Apod apod;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: <Widget>[
        if (apod.imageUrl case final String url)
          ApodImage(url: url, semanticLabel: apod.title)
        else if (apod.isImage)
          const _MissingImageNotice()
        else
          _VideoCard(apod: apod),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(apod.displayTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                _subtitle(apod),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _FavoriteButton(apod: apod),
              const SizedBox(height: 20),
              Text(apod.explanation, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  /// `22 October 2026` plus the credit when NASA is not the owner.
  static String _subtitle(Apod apod) {
    final String date = formatApodDate(apod.date);
    final String? credit = apod.copyright;
    if (credit == null || credit.isEmpty) return date;
    return '$date  ·  © $credit';
  }
}

/// Shown when the feed reports an image but sends no usable picture.
///
/// NASA's APOD feed intermittently answers with a placeholder record: the
/// explanation is real, but the image fields point at the site logo. Saying so
/// is better than rendering a logo as if it were the astronomy picture.
class _MissingImageNotice extends StatelessWidget {
  const _MissingImageNotice();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: 240,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No picture available for this date',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'NASA\'s feed did not send an image for this entry. '
            'The description below is still today\'s.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Stands in for the picture when the day's entry is a video.
///
/// A video URL cannot be rendered by an image widget, so this shows a poster
/// frame and a button that opens the video in the browser.
class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.apod});

  final Apod apod;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: 240,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.play_circle_outline,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('Today\'s entry is a video', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _openVideo(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Watch video'),
          ),
        ],
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Uri? uri = Uri.tryParse(apod.url);

    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the video link.')),
      );
    }
  }
}

/// Adds or removes this APOD from the favorites list.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.apod});

  final Apod apod;

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider favorites = context.watch<FavoritesProvider>();
    final bool saved = favorites.contains(FavoriteType.apod, apod.date);

    return FilledButton.tonalIcon(
      onPressed: () => favorites.toggle(
        FavoriteItem(
          id: apod.date,
          type: FavoriteType.apod,
          title: apod.displayTitle,
        ),
      ),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      label: Text(saved ? 'Saved to favorites' : 'Save to favorites'),
    );
  }
}
