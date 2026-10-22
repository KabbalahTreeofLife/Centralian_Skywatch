import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/utils/date_format.dart';

void main() {
  group('formatDate', () {
    test('formats a date as day, month name and year', () {
      expect(formatDate(DateTime(2026, 10, 22)), '22 October 2026');
    });

    test('does not zero-pad the day', () {
      expect(formatDate(DateTime(2026, 1, 5)), '5 January 2026');
    });

    test('handles the last month of the year', () {
      expect(formatDate(DateTime(2026, 12, 31)), '31 December 2026');
    });
  });

  group('formatApodDate', () {
    test('formats the APOD calendar date', () {
      expect(formatApodDate('2026-10-22'), '22 October 2026');
    });

    test('keeps the day stable regardless of the local time zone', () {
      // The APOD date is a calendar date, not an instant, so it must not shift.
      expect(formatApodDate('2026-01-01'), '1 January 2026');
    });

    test('returns the raw value when it cannot be parsed', () {
      expect(formatApodDate('not a date'), 'not a date');
    });

    test('returns an empty string unchanged', () {
      expect(formatApodDate(''), '');
    });
  });
}
