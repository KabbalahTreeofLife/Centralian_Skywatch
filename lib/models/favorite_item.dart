import 'json_utils.dart';

/// The kind of content a favorite points at.
enum FavoriteType {
  apod,
  launch;

  /// Value written to local storage.
  String get storageValue => name;

  /// Reads a stored value, defaulting to [FavoriteType.apod] when unknown.
  static FavoriteType fromStorage(Object? value) {
    return FavoriteType.values.firstWhere(
      (FavoriteType type) => type.name == value,
      orElse: () => FavoriteType.apod,
    );
  }
}

/// A saved APOD entry or launch, with an optional personal note.
///
/// This is the entity the app performs CRUD on: favorites are created from the
/// Home and Launches screens, read on the Favorites screen, updated when the
/// note changes, and deleted from the list.
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.type,
    required this.title,
    this.note = '',
  });

  final String id;
  final FavoriteType type;
  final String title;
  final String note;

  FavoriteItem copyWith({String? title, String? note}) => FavoriteItem(
    id: id,
    type: type,
    title: title ?? this.title,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.storageValue,
    'title': title,
    'note': note,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: readString(json['id']),
    type: FavoriteType.fromStorage(json['type']),
    title: readString(json['title']),
    note: readString(json['note']),
  );
}
