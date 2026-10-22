import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/utils/countdown.dart';

void main() {
  group('formatCountdown', () {
    final DateTime net = DateTime.utc(2026, 10, 22, 22, 51, 18);

    test('counts down to a future launch', () {
      final DateTime now = net.subtract(
        const Duration(hours: 2, minutes: 14, seconds: 33),
      );

      expect(formatCountdown(net, now), 'T-02:14:33');
    });

    test('reads zero at the moment of launch', () {
      expect(formatCountdown(net, net), 'T-00:00:00');
    });

    test('counts up after the launch', () {
      final DateTime now = net.add(const Duration(minutes: 3, seconds: 12));

      expect(formatCountdown(net, now), 'T+00:03:12');
    });

    test('folds days into the hours field', () {
      final DateTime now = net.subtract(const Duration(days: 3));

      expect(formatCountdown(net, now), 'T-72:00:00');
    });

    test('pads every field to a fixed width', () {
      final DateTime now = net.subtract(
        const Duration(hours: 1, minutes: 2, seconds: 3),
      );

      expect(formatCountdown(net, now), 'T-01:02:03');
    });

    test('truncates sub-second differences rather than rounding up', () {
      // 900ms before launch is still T-00:00:00, not T-00:00:01.
      final DateTime now = net.subtract(const Duration(milliseconds: 900));

      expect(formatCountdown(net, now), 'T-00:00:00');
    });

    test('handles a launch more than a day in the past', () {
      final DateTime now = net.add(const Duration(days: 2, hours: 1));

      expect(formatCountdown(net, now), 'T+49:00:00');
    });
  });

  group('isWithinCountdownWindow', () {
    final DateTime net = DateTime.utc(2026, 10, 22, 22, 51, 18);

    test('is true for a launch later today', () {
      expect(
        isWithinCountdownWindow(net, net.subtract(const Duration(hours: 3))),
        isTrue,
      );
    });

    test('is true at the boundary', () {
      expect(
        isWithinCountdownWindow(net, net.subtract(countdownWindow)),
        isTrue,
      );
    });

    test('is false beyond the window', () {
      expect(
        isWithinCountdownWindow(net, net.subtract(const Duration(days: 8))),
        isFalse,
      );
    });

    test('is false once the launch has passed', () {
      expect(
        isWithinCountdownWindow(net, net.add(const Duration(minutes: 1))),
        isFalse,
      );
    });
  });
}
