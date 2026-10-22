/// Countdown formatting for upcoming launches.
///
/// Kept as a pure function rather than a widget so it can be tested directly,
/// without pumping a clock through the widget tree. The caller supplies `now`,
/// which is what makes that possible.
library;

/// Formats the time from [now] to [net] as a T-minus / T-plus string.
///
/// Returns `T-02:14:33` before the launch, `T-00:00:00` at the moment itself,
/// and `T+00:03:12` after it. Days are folded into the hours field, so a launch
/// three days out reads `T-72:00:00` rather than losing the days.
///
/// The result is always signed and zero-padded to a fixed width, so the text
/// does not jitter as the digits change.
String formatCountdown(DateTime net, DateTime now) {
  final Duration remaining = net.difference(now);
  final bool past = remaining.isNegative;
  final Duration magnitude = past ? -remaining : remaining;

  final String hours = magnitude.inHours.toString().padLeft(2, '0');
  final String minutes = (magnitude.inMinutes % 60).toString().padLeft(2, '0');
  final String seconds = (magnitude.inSeconds % 60).toString().padLeft(2, '0');

  return 'T${past ? '+' : '-'}$hours:$minutes:$seconds';
}

/// Whether [net] is close enough to be worth counting down to the second.
///
/// Beyond this the seconds tick too fast to read, so the UI shows the date
/// instead of a countdown.
const Duration countdownWindow = Duration(days: 7);

/// Whether [net] falls inside [countdownWindow] of [now].
bool isWithinCountdownWindow(DateTime net, DateTime now) {
  final Duration remaining = net.difference(now);
  return !remaining.isNegative && remaining <= countdownWindow;
}
