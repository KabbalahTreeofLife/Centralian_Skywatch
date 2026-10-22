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
          ApodImage(url: url, semanticLabel: apod.alt ?? apod.title)
        else
          const _MissingImageNotice(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(apod.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                _subtitle(apod),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (apod.isVideo) ...<Widget>[
                const SizedBox(height: 16),
                _VideoButton(apod: apod),
              ],
              const SizedBox(height: 16),
              _FavoriteButton(apod: apod),
              const SizedBox(height: 20),
              _Explanation(apod: apod),
            ],
          ),
        ),
      ],
    );
  }

  /// `22 October 2026` plus the credit when one is given.
  static String _subtitle(Apod apod) {
    final String date = formatApodDate(apod.date);
    final String? credit = apod.credit;
    if (credit == null || credit.isEmpty) return date;
    return '$date  ·  $credit';
  }
}

/// The description, laid out for reading.
///
/// The feed sends one long run of prose, so the text is justified and given
/// generous line height. Paragraph breaks are kept, and the trailing note about
/// the next entry is shown separately rather than run into the description.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.apod});

  final Apod apod;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? body = theme.textTheme.bodyMedium?.copyWith(
      height: 1.6,
      letterSpacing: 0.1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String paragraph in apod.paragraphs) ...<Widget>[
          Text(
            paragraph,
            style: body,
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 14),
        ],
        if (apod.tomorrowTeaser case final String teaser)
          _TomorrowTeaser(text: teaser),
      ],
    );
  }
}

/// The feed's note about the next entry.
///
/// It is not part of today's description, so it is set apart in a tinted box
/// rather than appended to the prose.
class _TomorrowTeaser extends StatelessWidget {
  const _TomorrowTeaser({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.arrow_forward,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the feed sends an entry with no picture at all.
///
/// The feed normally always carries a still frame, even for videos, so this is
/// a genuine gap rather than the common case.
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
            'No picture for this entry',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'NASA\'s feed did not include an image. '
            'The description below is still today\'s entry.',
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

/// Opens the entry's page, where a video can be played.
///
/// The feed gives a still frame for video entries, so the picture is already on
/// screen; this button is how the video itself is reached.
class _VideoButton extends StatelessWidget {
  const _VideoButton({required this.apod});

  final Apod apod;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Watch video'),
    );
  }

  Future<void> _open(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? link = apod.permalink;
    final Uri? uri = link == null ? null : Uri.tryParse(link);

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
          title: apod.title,
        ),
      ),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      label: Text(saved ? 'Saved to favorites' : 'Save to favorites'),
    );
  }
}
