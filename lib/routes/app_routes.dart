/// Named routes used across Centralian Skywatch.
///
/// The four tab routes open the [MainScaffold] shell at the matching tab;
/// [launchDetail] is pushed on top of the shell.
class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String launches = '/launches';
  static const String iss = '/iss';
  static const String favorites = '/favorites';
  static const String launchDetail = '/launch-detail';
}
