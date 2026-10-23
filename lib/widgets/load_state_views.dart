/// The three states every data-backed screen shares.
///
/// They live here rather than inside a screen so the Launches, Launch Detail,
/// ISS and Favorites screens all render the same loading, error and empty
/// states instead of each growing its own copy.
library;

import 'package:flutter/material.dart';

import '../services/api_exception.dart';

/// How a failed request should be presented: an icon, and a title naming the
/// cause when the user can act on it.
///
/// Screens share this so the same failure looks the same everywhere instead of
/// each one inventing its own wording. A generic failure carries no title
/// (`null`) because the screen knows what it was loading and can say so more
/// usefully than this function can.
///
/// Being offline is the case worth naming: it is the one the user can fix
/// themselves, so the wording points at their network rather than at the app.
({IconData icon, String? title}) describeFailure(ApiException? error) {
  if (error is NoInternetException) {
    return (icon: Icons.wifi_off, title: 'You are offline');
  }

  return (icon: Icons.error_outline, title: null);
}

/// Shown while a screen is waiting for its first response.
///
/// The spinner is paired with a message so the user knows what is loading, not
/// just that something is.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a request failed, with a way to try again.
///
/// [onRetry] is required: an error state the user cannot act on is a dead end.
///
/// [title] is for screens that can say *why* the request failed — the Home
/// screen distinguishes "You are offline" from a generic failure — while
/// [message] carries the detail underneath.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
    this.icon = Icons.cloud_off,
  });

  final String message;
  final VoidCallback onRetry;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? title = this.title;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            if (title != null) ...<Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
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

/// Shown when a request succeeded but there is nothing to display.
///
/// This is deliberately distinct from [ErrorRetryView]: an empty list is a
/// normal outcome, not a failure, so it carries no error colouring and no
/// retry button.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? message = this.message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
