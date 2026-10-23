import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/apod.dart';
import '../models/favorite_item.dart';
import '../providers/apod_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/load_status.dart';
import '../utils/date_format.dart';
import '../widgets/apod_image.dart';
import '../widgets/load_state_views.dart';

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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      child: switch (provider.status) {
        LoadStatus.success => _ApodView(
          key: ValueKey<String>(provider.data!.date),
          apod: provider.data!,
        ),
        LoadStatus.error => _plain(
          const ValueKey<String>('home_error'),
          _errorView(provider),
        ),
        LoadStatus.idle || LoadStatus.loading => _plain(
          const ValueKey<String>('home_loading'),
          const LoadingView(message: 'Loading today\'s picture…'),
        ),
      },
    );
  }

  /// Loading and error states keep a conventional bar.
  ///
  /// Only the loaded entry gets the full-bleed hero, because only it has a
  /// picture worth giving the whole screen to.
  Widget _plain(Key key, Widget body) {
    return Scaffold(
      key: key,
      appBar: AppBar(title: const Text('Today in Space')),
      body: body,
    );
  }

  /// The failure state, worded for the kind of failure.
  ///
  /// Being offline is named separately by [describeFailure]; anything else
  /// falls back to the wording this screen can offer, since it is the one that
  /// knows a picture was what failed to arrive.
  Widget _errorView(ApodProvider provider) {
    final ({IconData icon, String? title}) failure = describeFailure(
      provider.error,
    );

    return ErrorRetryView(
      icon: failure.icon,
      title: failure.title ?? 'Could not load the picture',
      message:
          provider.error?.message ?? 'Something went wrong. Please try again.',
      onRetry: () => provider.load(force: true),
    );
  }
}

/// The loaded picture, its details and the favorite button.
///
/// The picture is the screen: it fills a collapsing header, with the title and
/// date set on a scrim over its lower edge. Everything else scrolls beneath.
class _ApodView extends StatelessWidget {
  const _ApodView({required this.apod, super.key});

  final Apod apod;

  /// How tall the picture is before it collapses into the bar.
  static const double _heroHeight = 420;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: _heroHeight,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('Today in Space'),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _Hero(apod: apod),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverList.list(
              children: <Widget>[
                if (apod.isVideo) ...<Widget>[
                  _VideoButton(apod: apod),
                  const SizedBox(height: 12),
                ],
                _FavoriteButton(apod: apod),
                if (apod.imageUrl == null) ...<Widget>[
                  const SizedBox(height: 20),
                  const _MissingImageNotice(),
                ],
                const SizedBox(height: 28),
                _Explanation(apod: apod),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The picture, its scrims, and the title laid over the bottom edge.
class _Hero extends StatelessWidget {
  const _Hero({required this.apod});

  final Apod apod;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? url = apod.imageUrl;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (url != null)
          Hero(
            tag: 'apod-hero-${apod.date}',
            child: ApodImage(url: url, semanticLabel: apod.alt ?? apod.title),
          )
        else
          const _Starfield(),
        // Top scrim: keeps the bar title legible over a bright photograph.
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
        // Bottom scrim: the title and date sit on a solid base.
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
              stops: const <double>[0, 0.7, 1],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                apod.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle(apod),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
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

/// Backdrop for an entry that arrived without a picture.
///
/// A soft glow rather than a flat grey, so the header still reads as part of
/// the same screen instead of a hole in it.
class _Starfield extends StatelessWidget {
  const _Starfield();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.2, -0.6),
          radius: 1.1,
          colors: <Color>[
            scheme.primary.withValues(alpha: 0.35),
            scheme.surface,
          ],
        ),
      ),
    );
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
    final TextStyle? body = theme.textTheme.bodyLarge?.copyWith(
      height: 1.65,
      letterSpacing: 0.1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String paragraph in apod.paragraphs) ...<Widget>[
          Text(paragraph, style: body, textAlign: TextAlign.justify),
          const SizedBox(height: 16),
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
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.arrow_forward, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
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
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: scheme.onSurfaceVariant,
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
              color: scheme.onSurfaceVariant,
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
        FavoriteItem(id: apod.date, type: FavoriteType.apod, title: apod.title),
      ),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      label: Text(saved ? 'Saved to favorites' : 'Save to favorites'),
    );
  }
}
