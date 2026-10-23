import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the project requirement that the three shared state widgets are each
/// used on more than one screen, and that no screen has quietly grown its own
/// copy again.
///
/// This reads the screen sources rather than pumping widgets: the property
/// being checked is "how many screens use this", which is a fact about the
/// codebase, not about any single rendered frame.
void main() {
  final Directory screens = Directory('lib/screens');

  /// Source text of every screen, keyed by file name.
  Map<String, String> screenSources() {
    return <String, String>{
      for (final FileSystemEntity entity in screens.listSync())
        if (entity is File && entity.path.endsWith('.dart'))
          entity.uri.pathSegments.last: entity.readAsStringSync(),
    };
  }

  group('shared state widgets', () {
    test('the screens directory exists', () {
      expect(screens.existsSync(), isTrue);
    });

    for (final String widget in <String>[
      'LoadingView',
      'ErrorRetryView',
      'EmptyStateView',
    ]) {
      test('$widget is used on at least two screens', () {
        final Map<String, String> sources = screenSources();
        final List<String> users = <String>[
          for (final MapEntry<String, String> entry in sources.entries)
            if (entry.value.contains(widget)) entry.key,
        ];

        expect(
          users.length,
          greaterThanOrEqualTo(2),
          reason: '$widget is only used on $users',
        );
      });
    }

    test('no screen defines its own loading, error or empty state', () {
      // The private classes these widgets replaced. If one reappears, a screen
      // has started duplicating state UI again.
      const List<String> banned = <String>[
        'class _LoadingState',
        'class _ErrorState',
        'class _EmptyState',
      ];

      for (final MapEntry<String, String> entry in screenSources().entries) {
        for (final String declaration in banned) {
          expect(
            entry.value.contains(declaration),
            isFalse,
            reason: '${entry.key} re-implements $declaration',
          );
        }
      }
    });
  });
}
