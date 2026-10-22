import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:centralian_skywatch/models/favorite_item.dart';
import 'package:centralian_skywatch/providers/favorites_provider.dart';

const FavoriteItem _apod = FavoriteItem(
  id: '2026-10-22',
  type: FavoriteType.apod,
  title: 'NASA Science',
);

const FavoriteItem _launch = FavoriteItem(
  id: '2026-10-22',
  type: FavoriteType.launch,
  title: 'Falcon 9 | Test',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('FavoritesProvider', () {
    test('starts empty and not loaded', () {
      final FavoritesProvider provider = FavoritesProvider();

      expect(provider.isLoaded, isFalse);
      expect(provider.isEmpty, isTrue);
      expect(provider.count, 0);
    });

    test('load marks the provider ready', () async {
      final FavoritesProvider provider = FavoritesProvider();

      await provider.load();

      expect(provider.isLoaded, isTrue);
      expect(provider.isEmpty, isTrue);
    });

    test('add saves the item and notifies once', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();
      int notifications = 0;
      provider.addListener(() => notifications++);

      final bool added = await provider.add(_apod);

      expect(added, isTrue);
      expect(provider.count, 1);
      expect(provider.contains(FavoriteType.apod, '2026-10-22'), isTrue);
      expect(notifications, 1);
    });

    test('add rejects a duplicate', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();

      expect(await provider.add(_apod), isTrue);
      expect(await provider.add(_apod), isFalse);
      expect(provider.count, 1);
    });

    test('the same id can be saved once per type', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();

      expect(await provider.add(_apod), isTrue);
      expect(await provider.add(_launch), isTrue);
      expect(provider.count, 2);
    });

    test('remove deletes the item', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();
      await provider.add(_apod);

      await provider.remove(FavoriteType.apod, '2026-10-22');

      expect(provider.isEmpty, isTrue);
    });

    test('remove ignores an unknown item', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();

      await provider.remove(FavoriteType.apod, 'missing');

      expect(provider.isEmpty, isTrue);
    });

    test('updateNote replaces the note and trims it', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();
      await provider.add(_apod);

      await provider.updateNote(FavoriteType.apod, '2026-10-22', '  Look up  ');

      expect(provider.items.single.note, 'Look up');
    });

    test('updateNote ignores a missing item', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();

      await provider.updateNote(FavoriteType.apod, 'missing', 'note');

      expect(provider.isEmpty, isTrue);
    });

    test('toggle adds then removes', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();

      await provider.toggle(_apod);
      expect(provider.count, 1);

      await provider.toggle(_apod);
      expect(provider.isEmpty, isTrue);
    });

    test('favorites survive a restart', () async {
      final FavoritesProvider first = FavoritesProvider();
      await first.load();
      await first.add(_apod);
      await first.updateNote(FavoriteType.apod, '2026-10-22', 'Saved note');

      // A second provider over the same storage stands in for a fresh start.
      final FavoritesProvider second = FavoritesProvider();
      await second.load();

      expect(second.count, 1);
      expect(second.items.single.title, 'NASA Science');
      expect(second.items.single.note, 'Saved note');
    });

    test('load is idempotent', () async {
      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();
      await provider.add(_apod);

      await provider.load();

      expect(provider.count, 1);
    });

    test('skips a malformed stored entry', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        FavoritesProvider.storageKey: <String>[
          'not json',
          '{"id":"2026-10-22","type":"apod","title":"NASA Science","note":""}',
        ],
      });

      final FavoritesProvider provider = FavoritesProvider();
      await provider.load();

      expect(provider.count, 1);
      expect(provider.items.single.title, 'NASA Science');
    });
  });
}
