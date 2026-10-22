import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/favorite_item.dart';

void main() {
  group('FavoriteItem', () {
    test('round-trips through JSON', () {
      const FavoriteItem original = FavoriteItem(
        id: 'f6af629d-39b5-4f86-bc0c-f8776444a858',
        type: FavoriteType.launch,
        title: 'Falcon 9 Block 5 | Starlink Group 15-15',
        note: 'Watch with the class',
      );

      final Map<String, dynamic> encoded = original.toJson();
      final FavoriteItem decoded = FavoriteItem.fromJson(
        jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
      );

      expect(decoded.id, original.id);
      expect(decoded.type, FavoriteType.launch);
      expect(decoded.title, original.title);
      expect(decoded.note, original.note);
    });

    test('stores the type as a readable string', () {
      const FavoriteItem item = FavoriteItem(
        id: 'apod-2026-10-22',
        type: FavoriteType.apod,
        title: 'NASA Science',
      );

      expect(item.toJson()['type'], 'apod');
      expect(item.note, '');
    });

    test('falls back to apod for an unknown stored type', () {
      final FavoriteItem item = FavoriteItem.fromJson(<String, dynamic>{
        'id': 'x',
        'type': 'something-else',
        'title': 'Title',
      });

      expect(item.type, FavoriteType.apod);
    });

    test('survives missing fields', () {
      final FavoriteItem item = FavoriteItem.fromJson(<String, dynamic>{});

      expect(item.id, '');
      expect(item.type, FavoriteType.apod);
      expect(item.title, '');
      expect(item.note, '');
    });

    test('copyWith updates the note without touching identity', () {
      const FavoriteItem item = FavoriteItem(
        id: 'x',
        type: FavoriteType.launch,
        title: 'Title',
      );

      final FavoriteItem updated = item.copyWith(note: 'Updated note');

      expect(updated.id, item.id);
      expect(updated.type, item.type);
      expect(updated.title, item.title);
      expect(updated.note, 'Updated note');
      expect(item.note, '');
    });
  });
}
