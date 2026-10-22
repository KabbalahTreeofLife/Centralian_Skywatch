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
import 'package:centralian_skywatch/screens/main_scaffold.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/apod_service.dart';
import 'package:centralian_skywatch/services/iss_service.dart';
import 'package:centralian_skywatch/services/launch_service.dart';

const String _apodJson =
    '{"date":"2026-10-22","title":"NASA Science","media_type":"image",'
    '"url":"https://example.test/a.jpg"}';

const String _launchJson =
    '{"count":1,"results":[{"id":"a","name":"Falcon 9 | Test",'
    '"status":{"name":"Go"},"net":"2026-10-22T22:51:18Z","lsp_name":"SpaceX"}]}';

const String _issJson =
    '{"latitude":1.5,"longitude":2.5,"velocity":27570,"timestamp":1792683638}';

/// Taps a bottom-navigation destination by its label.
///
/// Scoped to the [NavigationBar] because some screens use the same word in
/// their app bar title.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('switching tabs never refetches', (WidgetTester tester) async {
    int apodCalls = 0;
    int launchCalls = 0;
    int issCalls = 0;

    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        switch (request.url.host) {
          case 'api.nasa.gov':
            apodCalls++;
            return http.Response(_apodJson, 200);
          case 'll.thespacedevs.com':
            launchCalls++;
            return http.Response(_launchJson, 200);
          case 'api.wheretheiss.at':
            issCalls++;
            return http.Response(_issJson, 200);
        }
        return http.Response('', 404);
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
        child: const MaterialApp(home: MainScaffold()),
      ),
    );
    await tester.pumpAndSettle();

    // IndexedStack builds every tab, so all three load once at startup.
    expect(apodCalls, 1);
    expect(launchCalls, 1);
    expect(issCalls, 1);

    for (final String tab in <String>['Launches', 'ISS', 'Favorites', 'Home']) {
      await tapTab(tester, tab);
    }

    expect(apodCalls, 1);
    expect(launchCalls, 1);
    expect(issCalls, 1);
  });

  testWidgets('a failed load shows the error and Retry refetches', (
    WidgetTester tester,
  ) async {
    int apodCalls = 0;
    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        switch (request.url.host) {
          case 'api.nasa.gov':
            apodCalls++;
            // Fail the first attempt only, so Retry has something to fix.
            if (apodCalls == 1) return http.Response('', 500);
            return http.Response(_apodJson, 200);
          case 'll.thespacedevs.com':
            return http.Response(_launchJson, 200);
          case 'api.wheretheiss.at':
            return http.Response(_issJson, 200);
        }
        return http.Response('', 404);
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
        child: const MaterialApp(home: MainScaffold()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(apodCalls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(apodCalls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('NASA Science'), findsOneWidget);
  });

  testWidgets('a cold start that fails recovers on the next load', (
    WidgetTester tester,
  ) async {
    // The reported bug: the app launches with no network, every tab fails, and
    // the app is then stuck on the error screen. A later load() must be able to
    // recover without the user hunting for Retry.
    int apodCalls = 0;
    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        switch (request.url.host) {
          case 'api.nasa.gov':
            apodCalls++;
            if (apodCalls == 1) throw http.ClientException('offline');
            return http.Response(_apodJson, 200);
          case 'll.thespacedevs.com':
            return http.Response(_launchJson, 200);
          case 'api.wheretheiss.at':
            return http.Response(_issJson, 200);
        }
        return http.Response('', 404);
      }),
      backoffBase: Duration.zero,
    );

    final ApodProvider apod = ApodProvider(
      service: ApodService(apiKey: 'TEST', client: client),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApodProvider>.value(value: apod),
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
        child: const MaterialApp(home: MainScaffold()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are offline'), findsOneWidget);
    expect(apodCalls, 1);

    // The network comes back and something calls load() again, as a rebuilt
    // screen does. It must actually retry.
    await apod.load();
    await tester.pumpAndSettle();

    expect(apodCalls, 2);
    expect(find.text('You are offline'), findsNothing);
    expect(find.textContaining('NASA Science'), findsOneWidget);
  });
}
