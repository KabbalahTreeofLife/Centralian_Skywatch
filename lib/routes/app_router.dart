import 'package:flutter/material.dart';

import '../screens/launch_detail_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/not_found_screen.dart';
import 'app_routes.dart';

/// Maps a route name to its screen.
///
/// The four tab routes open the [MainScaffold] shell at the matching tab and
/// [AppRoutes.launchDetail] is pushed on top of it. Unknown names fall back to
/// [NotFoundScreen] so a bad link never crashes the app.
Route<dynamic> buildRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => const MainScaffold(initialIndex: 0),
      );
    case AppRoutes.launches:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => const MainScaffold(initialIndex: 1),
      );
    case AppRoutes.iss:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => const MainScaffold(initialIndex: 2),
      );
    case AppRoutes.favorites:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => const MainScaffold(initialIndex: 3),
      );
    case AppRoutes.launchDetail:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => const LaunchDetailScreen(),
      );
    default:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) =>
            NotFoundScreen(routeName: settings.name),
      );
  }
}

/// Builds the initial route stack.
///
/// Flutter's default handling also pushes '/' underneath the requested route,
/// which would leave the not-found screen below the shell. Building a single
/// root route keeps Back behaviour predictable.
List<Route<dynamic>> buildInitialRoutes(String initialRoute) =>
    <Route<dynamic>>[buildRoute(RouteSettings(name: initialRoute))];
