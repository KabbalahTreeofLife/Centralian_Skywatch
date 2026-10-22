import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'providers/apod_provider.dart';
import 'providers/iss_provider.dart';
import 'providers/launch_provider.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'services/api_client.dart';
import 'services/apod_service.dart';
import 'services/iss_service.dart';
import 'services/launch_service.dart';
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
    return MultiProvider(
      providers: [
        // One client for the whole app, so every service shares a single
        // connection pool and it is closed exactly once.
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, ApiClient client) => client.close(),
        ),
        ChangeNotifierProvider<ApodProvider>(
          create: (BuildContext context) => ApodProvider(
            service: ApodService(
              apiKey: AppConfig.nasaApiKey,
              client: context.read<ApiClient>(),
            ),
          ),
        ),
        ChangeNotifierProvider<LaunchProvider>(
          create: (BuildContext context) => LaunchProvider(
            service: LaunchService(client: context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<IssProvider>(
          create: (BuildContext context) => IssProvider(
            service: IssService(client: context.read<ApiClient>()),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Centralian Skywatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.home,
        onGenerateRoute: buildRoute,
        onGenerateInitialRoutes: buildInitialRoutes,
      ),
    );
  }
}
