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
  /// Returns true only when the item is now saved in local storage. It returns
  /// false when the item was already saved or when storage rejected the write;
  /// in both cases nothing changed, so the list never shows a favorite that
  /// would be gone after a restart.
  Future<bool> add(FavoriteItem item) => _serial(() => _addNow(item));

  /// Removes the favorite with [id] of [type], if present.
  ///
  /// Returns true only when the removal reached local storage. Returns false
  /// when there was nothing to remove or when storage rejected the write.
  Future<bool> remove(FavoriteType type, String id) =>
      _serial(() => _removeNow(type, id));

  /// Replaces the note on an existing favorite.
  ///
  /// Does nothing when the favorite is gone, so a dialog left open on a deleted
  /// item cannot resurrect it. Returns true only when the new note reached
  /// local storage.
  Future<bool> updateNote(FavoriteType type, String id, String note) =>
      _serial(() => _updateNoteNow(type, id, note));

  /// Adds [item] when absent, removes it when present.
  ///
  /// Returns true only when the change reached local storage.
  Future<bool> toggle(FavoriteItem item) {
    return _serial(() {
      if (contains(item.type, item.id)) return _removeNow(item.type, item.id);
      return _addNow(item);
    });
  }

  /// The end of the queue of pending changes.
  ///
  /// Each change is computed from the list as it stands once the previous one
  /// has finished. Two quick taps would otherwise both start from the same
  /// list, and the second write would silently discard the first.
  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() change) {
    final Future<T> result = _tail.then((_) => change());
    _tail = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<bool> _addNow(FavoriteItem item) {
    if (contains(item.type, item.id)) return Future<bool>.value(false);
    return _commit(<FavoriteItem>[item, ..._items]);
  }

  Future<bool> _removeNow(FavoriteType type, String id) {
    final int index = _indexOf(type, id);
    if (index == -1) return Future<bool>.value(false);

    final List<FavoriteItem> next = <FavoriteItem>[..._items];
    next.removeAt(index);
    return _commit(next);
  }

  Future<bool> _updateNoteNow(FavoriteType type, String id, String note) {
    final int index = _indexOf(type, id);
    if (index == -1) return Future<bool>.value(false);

    final List<FavoriteItem> next = <FavoriteItem>[..._items];
    next[index] = next[index].copyWith(note: note.trim());
    return _commit(next);
  }

  int _indexOf(FavoriteType type, String id) => _items.indexWhere(
    (FavoriteItem item) => item.type == type && item.id == id,
  );

  /// Writes [next] to storage, and only then makes it the visible list.
  ///
  /// `setStringList` reports failure by returning false rather than throwing,
  /// so the result is checked: a rejected write leaves the list untouched.
  Future<bool> _commit(List<FavoriteItem> next) async {
    final bool saved = await _persist(next);
    if (!saved) {
      debugPrint('Could not write favorites to local storage.');
      return false;
    }

    _items
      ..clear()
      ..addAll(next);
    notifyListeners();
    return true;
  }

  Future<bool> _persist(List<FavoriteItem> items) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      return await preferences.setStringList(
        storageKey,
        items
            .map((FavoriteItem item) => jsonEncode(item.toJson()))
            .toList(growable: false),
      );
    } catch (error) {
      debugPrint('Favorites write failed: $error');
      return false;
    }
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
