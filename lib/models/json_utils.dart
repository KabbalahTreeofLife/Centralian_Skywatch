/// Defensive helpers for reading JSON values.
///
/// The APIs used by this app occasionally omit fields or send `null`, so every
/// model reads through these helpers instead of casting directly. A missing
/// field then produces a safe default instead of a runtime crash.
library;

/// Reads a string, falling back when the value is missing or not a string.
String readString(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

/// Reads a string, returning null when it is missing or empty.
String? readStringOrNull(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

/// Reads a number, falling back when the value is missing or unparseable.
double readDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads an integer, falling back when the value is missing or unparseable.
int readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Parses an ISO-8601 timestamp into a UTC [DateTime].
///
/// Returns null when the value is missing or malformed, so callers can decide
/// how to present an unknown time instead of receiving a fabricated one.
DateTime? readDateTimeOrNull(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

/// Reads a nested JSON object, returning an empty map when absent.
Map<String, dynamic> readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}
