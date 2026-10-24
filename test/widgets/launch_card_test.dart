import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/widgets/launch_card.dart';

void main() {
  group('isGoForLaunch', () {
    test('is true for Go for Launch', () {
      expect(isGoForLaunch('Go for Launch'), isTrue);
    });

    test('ignores case and surrounding whitespace', () {
      expect(isGoForLaunch('  go for launch '), isTrue);
    });

    test('is false for No-Go, which contains the letters "go"', () {
      expect(isGoForLaunch('No-Go'), isFalse);
      expect(isGoForLaunch('No Go'), isFalse);
    });

    test('is false for the other launch statuses', () {
      for (final String status in <String>[
        'To Be Determined',
        'To Be Confirmed',
        'Hold',
        'In Flight',
        'Launch Successful',
        'Unknown',
        '',
      ]) {
        expect(isGoForLaunch(status), isFalse, reason: status);
      }
    });
  });
}
