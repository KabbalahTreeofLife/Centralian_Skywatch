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

/// Strips HTML tags and decodes the common entities.
///
/// NASA's APOD feed returns `explanation` and `copyright` as HTML, with links
/// and emphasis. The app shows plain text, so the markup is removed rather than
/// rendered. Unknown entities are left alone instead of being dropped.
String stripHtml(Object? value) {
  final String raw = readString(value);
  if (raw.isEmpty) return '';

  final String withoutTags = raw
      // Drop script and style bodies entirely, not just their tags.
      .replaceAll(RegExp(r'<(script|style)\b.*?</\1>', caseSensitive: false, dotAll: true), ' ')
      // Replace block-level tags with a space so words do not run together,
      // then remove the remaining inline tags outright. Removing inline tags
      // with a space would turn "Garlick</a>/<a>Warwick" into "Garlick / Warwick".
      .replaceAll(RegExp(r'</?(p|div|br|li|ul|ol|h[1-6]|tr|td|blockquote)\b[^>]*>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '');

  final String decoded = withoutTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&hellip;', '…')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–');

  // Collapse the whitespace the tag removal leaves behind.
  return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
}
