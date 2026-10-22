import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_item.dart';

/// Holds the user's saved APOD entries and launches.
///
/// Favorites are the entity the app performs CRUD on. They are keyed by
/// `(type, id)`, so an APOD and a launch that happen to share an id stay
/// distinct, and duplicates are impossible.
class FavoritesProvider extends ChangeNotifier {
  /// Key used in [SharedPreferences].
  static const String storageKey = 'favorites';

  final List<FavoriteItem> _items = <FavoriteItem>[];
  bool _loaded = false;

  /// The saved items, newest first.
  List<FavoriteItem> get items => List<FavoriteItem>.unmodifiable(_items);

  /// Whether [load] has finished at least once.
  bool get isLoaded => _loaded;

  bool get isEmpty => _items.isEmpty;

  int get count => _items.length;

  /// Whether [id] of [type] is already saved.
  bool contains(FavoriteType type, String id) =>
      _items.any((FavoriteItem item) => item.type == type && item.id == id);

  /// Reads the saved favorites from local storage.
  ///
  /// Safe to call more than once; only the first call reads storage. Entries
  /// that cannot be decoded are skipped, so one bad record cannot break the
  /// whole list.
  Future<void> load() async {
    if (_loaded) return;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> stored =
        preferences.getStringList(storageKey) ?? <String>[];

    _items
      ..clear()
      ..addAll(stored.map(_decode).whereType<FavoriteItem>());

    _loaded = true;
    notifyListeners();
  }

  /// Saves [item] unless it is already a favorite.
  ///
  /// Returns false when the item was already saved, so the caller can tell the
  /// user instead of silently doing nothing.
  Future<bool> add(FavoriteItem item) async {
    if (contains(item.type, item.id)) return false;

    _items.insert(0, item);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Removes the favorite with [id] of [type], if present.
  Future<void> remove(FavoriteType type, String id) async {
    final int index = _indexOf(type, id);
    if (index == -1) return;

    _items.removeAt(index);
    await _persist();
    notifyListeners();
  }

  /// Replaces the note on an existing favorite.
  ///
  /// Does nothing when the favorite is gone, so a dialog left open on a deleted
  /// item cannot resurrect it.
  Future<void> updateNote(FavoriteType type, String id, String note) async {
    final int index = _indexOf(type, id);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(note: note.trim());
    await _persist();
    notifyListeners();
  }

  /// Adds [item] when absent, removes it when present.
  Future<void> toggle(FavoriteItem item) async {
    if (contains(item.type, item.id)) {
      await remove(item.type, item.id);
    } else {
      await add(item);
    }
  }

  int _indexOf(FavoriteType type, String id) => _items.indexWhere(
    (FavoriteItem item) => item.type == type && item.id == id,
  );

  Future<void> _persist() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      storageKey,
      _items
          .map((FavoriteItem item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
  }

  static FavoriteItem? _decode(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return FavoriteItem.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }
}
