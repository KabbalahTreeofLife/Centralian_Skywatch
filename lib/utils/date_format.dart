/// Human-readable date formatting.
///
/// Deliberately hand-rolled instead of pulling in `intl`: the app only needs
/// one English format, and `intl` would add a dependency plus locale
/// initialisation for a single call site.
library;

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Formats [date] as `22 October 2026`.
String formatDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// Formats an APOD `date` field, which is a calendar date such as `2026-10-22`.
///
/// Returns [raw] unchanged when it cannot be parsed, so a surprising value from
/// the API is shown as-is rather than replaced with a wrong date.
String formatApodDate(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return formatDate(parsed);
}
