import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // .env is optional and gitignored, so a fresh clone has none. AppConfig
    // falls back to DEMO_KEY instead of letting the app fail to start.
  }
  runApp(const CentralianSkywatchApp());
}

class CentralianSkywatchApp extends StatelessWidget {
  const CentralianSkywatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centralian Skywatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      onGenerateRoute: buildRoute,
      onGenerateInitialRoutes: buildInitialRoutes,
    );
  }
}
