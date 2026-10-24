import 'package:flutter/material.dart';

/// Tells the user that a change to their favorites was not saved.
///
/// `FavoritesProvider` reports a rejected write by returning false, and it
/// leaves the list as it was, so the screen still shows the true state. This
/// is the one message every screen shows for that, so the wording does not
/// drift between them.
///
/// Takes the messenger rather than a context so callers can grab it before an
/// `await`, instead of using a context after the widget may have gone.
void showFavoriteSaveError(ScaffoldMessengerState messenger) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Could not save your favorites. Please try again.'),
      ),
    );
}
