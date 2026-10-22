import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:centralian_skywatch/providers/apod_provider.dart';
import 'package:centralian_skywatch/providers/favorites_provider.dart';
import 'package:centralian_skywatch/providers/iss_provider.dart';
import 'package:centralian_skywatch/providers/launch_provider.dart';
import 'package:centralian_skywatch/routes/app_router.dart';
import 'package:centralian_skywatch/routes/app_routes.dart';
import 'package:centralian_skywatch/screens/launch_detail_screen.dart';
import 'package:centralian_skywatch/screens/main_scaffold.dart';
import 'package:centralian_skywatch/screens/not_found_screen.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/apod_service.dart';
import 'package:centralian_skywatch/services/iss_service.dart';
import 'package:centralian_skywatch/services/launch_service.dart';

/// Providers backed by a client that always fails, so the screens settle into
/// their error state instead of waiting on a real network.
Widget withProviders(Widget child) {
  final ApiClient client = ApiClient(
    client: MockClient((http.Request request) async => http.Response('', 500)),
    backoffBase: Duration.zero,
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ApodProvider>(
        create: (_) => ApodProvider(
          service: ApodService(apiKey: 'TEST', client: client),
        ),
      ),
      ChangeNotifierProvider<LaunchProvider>(
        create: (_) => LaunchProvider(service: LaunchService(client: client)),
      ),
      ChangeNotifierProvider<IssProvider>(
        create: (_) => IssProvider(service: IssService(client: client)),
      ),
      ChangeNotifierProvider<FavoritesProvider>(
        create: (_) => FavoritesProvider()..load(),
      ),
    ],
    child: child,
  );
}

/// Pumps a bare app that uses the real route table, starting at [route].
Future<void> pumpAt(WidgetTester tester, String route) async {
  await tester.pumpWidget(
    withProviders(
      MaterialApp(
        // A changing key forces a fresh Navigator, otherwise re-pumping the same
        // widget type keeps the old route stack and ignores initialRoute.
        key: ValueKey<String>(route),
        initialRoute: route,
        onGenerateRoute: buildRoute,
        onGenerateInitialRoutes: buildInitialRoutes,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The tab currently shown by the shell's [IndexedStack].
int stackIndex(WidgetTester tester) =>
    tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('opens on the Home tab with the shell as the root route', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, AppRoutes.home);

    expect(find.byType(MainScaffold), findsOneWidget);
    expect(stackIndex(tester), 0);
    // The default initial-route handling would leave this underneath.
    expect(find.byType(NotFoundScreen), findsNothing);
  });

  testWidgets('each tab route opens the shell at the right tab', (
    WidgetTester tester,
  ) async {
    const Map<String, int> cases = <String, int>{
      AppRoutes.home: 0,
      AppRoutes.launches: 1,
      AppRoutes.iss: 2,
      AppRoutes.favorites: 3,
    };

    for (final MapEntry<String, int> entry in cases.entries) {
      await pumpAt(tester, entry.key);
      expect(
        find.byType(MainScaffold),
        findsOneWidget,
        reason: '${entry.key} should open the shell',
      );
      expect(
        stackIndex(tester),
        entry.value,
        reason: '${entry.key} should select tab ${entry.value}',
      );
      expect(find.byType(NotFoundScreen), findsNothing);
    }
  });

  testWidgets('tapping a destination switches tabs', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, AppRoutes.home);
    expect(stackIndex(tester), 0);

    await tester.tap(find.text('ISS'));
    await tester.pumpAndSettle();
    expect(stackIndex(tester), 2);
  });

  testWidgets('tapping a launch pushes Launch Detail with its argument', (
    WidgetTester tester,
  ) async {
    // This test needs a real launch to tap, so it uses its own client rather
    // than the always-failing one the other tests rely on.
    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        if (request.url.path.contains('/launch/upcoming')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'results': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'nav-launch',
                  'name': 'Falcon 9 Block 5 | Starlink Group',
                  'net': DateTime.now()
                      .toUtc()
                      .add(const Duration(hours: 2))
                      .toIso8601String(),
                  'status': <String, dynamic>{'name': 'Go for Launch'},
                  'lsp_name': 'SpaceX',
                  'mission_type': 'Communications',
                  'pad': 'SLC-4E',
                  'location': 'Vandenberg SFB, CA, USA',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('', 500);
      }),
      backoffBase: Duration.zero,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApodProvider>(
            create: (_) => ApodProvider(
              service: ApodService(apiKey: 'TEST', client: client),
            ),
          ),
          ChangeNotifierProvider<LaunchProvider>(
            create: (_) =>
                LaunchProvider(service: LaunchService(client: client)),
          ),
          ChangeNotifierProvider<IssProvider>(
            create: (_) => IssProvider(service: IssService(client: client)),
          ),
          ChangeNotifierProvider<FavoritesProvider>(
            create: (_) => FavoritesProvider()..load(),
          ),
        ],
        child: MaterialApp(
          key: const ValueKey<String>('nav-launch'),
          initialRoute: AppRoutes.launches,
          onGenerateRoute: buildRoute,
          onGenerateInitialRoutes: buildInitialRoutes,
        ),
      ),
    );

    // Explicit pumps: the Launches screen runs a one-second timer, so
    // pumpAndSettle would never finish.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Falcon 9 Block 5 | Starlink Group'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LaunchDetailScreen), findsOneWidget);
    expect(
      find.textContaining('Falcon 9 Block 5 | Starlink Group'),
      findsWidgets,
    );
  });

  testWidgets('an unknown route falls back to the not-found screen', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, '/does-not-exist');

    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.byType(MainScaffold), findsNothing);
  });
}
