import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:centralian_skywatch/models/favorite_item.dart';
import 'package:centralian_skywatch/providers/favorites_provider.dart';
import 'package:centralian_skywatch/providers/launch_provider.dart';
import 'package:centralian_skywatch/routes/app_routes.dart';
import 'package:centralian_skywatch/screens/launch_detail_screen.dart';
import 'package:centralian_skywatch/screens/launches_screen.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/launch_service.dart';
import 'package:centralian_skywatch/widgets/launch_card.dart';
import 'package:centralian_skywatch/widgets/load_state_views.dart';

/// A launch that is a few hours away, so it shows a countdown.
Map<String, dynamic> _soonLaunch() => <String, dynamic>{
  'id': 'launch-soon',
  'name': 'Falcon 9 Block 5 | Starlink Group 15-15',
  'net': DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String(),
  'status': <String, dynamic>{
    'name': 'Go for Launch',
    'description': 'Current T-0 confirmed by official or reliable sources.',
  },
  'lsp_name': 'SpaceX',
  'mission_type': 'Communications',
  'pad': 'Space Launch Complex 4E',
  'location': 'Vandenberg SFB, CA, USA',
  'image': 'https://example.test/patch.png',
};

/// A launch far enough out that it shows a date instead of a countdown.
Map<String, dynamic> _distantLaunch() => <String, dynamic>{
  'id': 'launch-distant',
  'name': 'Ariane 62 | Demo flight',
  'net': DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
  'status': <String, dynamic>{'name': 'To Be Determined', 'description': ''},
  'lsp_name': 'Arianespace',
  'mission_type': 'Test Flight',
  'pad': 'ELA-4',
  'location': 'Kourou, French Guiana',
  'image': null,
};

String _body(List<Map<String, dynamic>> launches) =>
    jsonEncode(<String, dynamic>{'results': launches});

/// Pumps the Launches screen over a client that answers with [body].
///
/// Uses explicit pumps rather than `pumpAndSettle`: the screen runs a
/// one-second timer, so settling would never finish.
Future<FavoritesProvider> pumpLaunches(
  WidgetTester tester, {
  required String body,
  int statusCode = 200,
  int failuresBeforeSuccess = 0,
  int failureStatusCode = 500,
  bool offline = false,
}) async {
  int calls = 0;
  final ApiClient client = ApiClient(
    client: MockClient((http.Request request) async {
      calls++;
      if (offline) {
        throw http.ClientException('Connection refused', request.url);
      }
      if (calls <= failuresBeforeSuccess) {
        return http.Response('', failureStatusCode);
      }
      return http.Response(body, statusCode);
    }),
    backoffBase: Duration.zero,
  );

  final FavoritesProvider favorites = FavoritesProvider();
  await favorites.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LaunchProvider>(
          create: (_) => LaunchProvider(service: LaunchService(client: client)),
        ),
        ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
      ],
      child: MaterialApp(
        home: const LaunchesScreen(),
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == AppRoutes.launchDetail) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const LaunchDetailScreen(),
            );
          }
          return null;
        },
      ),
    ),
  );

  // Let the post-frame load run and the response land.
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  return favorites;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows a loading view before the response arrives', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LaunchProvider>(
            create: (_) => LaunchProvider(
              service: LaunchService(
                client: ApiClient(
                  client: MockClient((_) async {
                    await Future<void>.delayed(const Duration(seconds: 5));
                    return http.Response(_body(<Map<String, dynamic>>[]), 200);
                  }),
                ),
              ),
            ),
          ),
          ChangeNotifierProvider<FavoritesProvider>(
            create: (_) => FavoritesProvider(),
          ),
        ],
        child: const MaterialApp(home: LaunchesScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.text('Loading launches.'), findsOneWidget);

    // Let the pending request finish so the timer is disposed cleanly.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('renders a card per launch', (WidgetTester tester) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[_soonLaunch(), _distantLaunch()]),
    );

    // The cards carry a photo banner, so only the first fits the test
    // viewport. The list is lazy, so the second is built once it scrolls in.
    expect(find.byType(LaunchCard), findsWidgets);
    expect(
      find.text('Falcon 9 Block 5 | Starlink Group 15-15'),
      findsOneWidget,
    );
    expect(find.text('SpaceX'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Ariane 62 | Demo flight'), 200);

    expect(find.text('Ariane 62 | Demo flight'), findsOneWidget);
    expect(find.text('Arianespace'), findsOneWidget);
  });

  testWidgets('shows a countdown for a launch that is close', (
    WidgetTester tester,
  ) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[_soonLaunch()]),
    );

    expect(
      find.textContaining(RegExp(r'^T-\d{2}:\d{2}:\d{2}$')),
      findsOneWidget,
    );
  });

  testWidgets('shows a date instead of a countdown for a distant launch', (
    WidgetTester tester,
  ) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[_distantLaunch()]),
    );

    expect(find.textContaining(RegExp(r'^T-\d{2}:\d{2}:\d{2}$')), findsNothing);
  });

  testWidgets('shows the empty state when there are no launches', (
    WidgetTester tester,
  ) async {
    await pumpLaunches(tester, body: _body(<Map<String, dynamic>>[]));

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('No upcoming launches'), findsOneWidget);
    expect(find.byType(LaunchCard), findsNothing);
  });

  testWidgets('shows the error state with Retry when the request fails', (
    WidgetTester tester,
  ) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[]),
      failuresBeforeSuccess: 99,
      failureStatusCode: 404,
    );

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // A server error is not the network being down, so it must not claim so.
    expect(find.text('You are offline'), findsNothing);
  });

  testWidgets('a transport failure names the offline case', (
    WidgetTester tester,
  ) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[]),
      offline: true,
    );

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Retry reloads and shows the list', (WidgetTester tester) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[_soonLaunch()]),
      failuresBeforeSuccess: 1,
      failureStatusCode: 404,
    );

    expect(find.byType(ErrorRetryView), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LaunchCard), findsOneWidget);
  });

  testWidgets('tapping a card opens the detail screen with that launch', (
    WidgetTester tester,
  ) async {
    await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[_soonLaunch()]),
    );

    await tester.tap(find.byType(LaunchCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LaunchDetailScreen), findsOneWidget);
    expect(find.text('Launch Detail'), findsOneWidget);

    // The hero image pushes the pad row below the fold in the test viewport.
    // Scope the scroll to the detail screen's own list: the launches list is
    // still mounted underneath, so there are two scrollables.
    await tester.scrollUntilVisible(
      find.text('Space Launch Complex 4E'),
      200,
      scrollable: find.descendant(
        of: find.byType(LaunchDetailScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Space Launch Complex 4E'), findsOneWidget);
  });

  testWidgets('the favorite toggle saves the launch', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider favorites = await pumpLaunches(
      tester,
      body: _body(<Map<String, dynamic>>[_soonLaunch()]),
    );

    expect(favorites.contains(FavoriteType.launch, 'launch-soon'), isFalse);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(favorites.contains(FavoriteType.launch, 'launch-soon'), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
