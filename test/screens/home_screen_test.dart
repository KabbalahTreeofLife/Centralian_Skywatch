import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:centralian_skywatch/models/favorite_item.dart';
import 'package:centralian_skywatch/providers/apod_provider.dart';
import 'package:centralian_skywatch/providers/favorites_provider.dart';
import 'package:centralian_skywatch/screens/home_screen.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/apod_service.dart';

const String _imageApodJson =
    '{"date":"2026-10-22","title":"NASA Science","media_type":"image",'
    '"url":"https://example.test/a.jpg","hdurl":"https://example.test/a-hd.jpg",'
    '"explanation":"A picture of something far away.",'
    '"copyright":"Jane Doe"}';

const String _videoApodJson =
    '{"date":"2026-10-21","title":"A Launch Video","media_type":"video",'
    '"url":"https://example.test/video","explanation":"A video entry."}';

/// Pumps the Home screen over a client that answers APOD requests with [body].
Future<FavoritesProvider> pumpHome(
  WidgetTester tester, {
  required String body,
  int statusCode = 200,
  int failuresBeforeSuccess = 0,
}) async {
  int calls = 0;
  final ApiClient client = ApiClient(
    client: MockClient((http.Request request) async {
      calls++;
      if (calls <= failuresBeforeSuccess) {
        return http.Response('', 500);
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
        ChangeNotifierProvider<ApodProvider>(
          create: (_) => ApodProvider(
            service: ApodService(apiKey: 'TEST', client: client),
          ),
        ),
        ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return favorites;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the title, date, credit and explanation', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _imageApodJson);

    expect(find.text('NASA Science'), findsOneWidget);
    expect(find.textContaining('22 October 2026'), findsOneWidget);
    expect(find.textContaining('Jane Doe'), findsOneWidget);
    expect(find.text('A picture of something far away.'), findsOneWidget);
  });

  testWidgets('omits the credit when NASA owns the picture', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _videoApodJson);

    expect(find.text('21 October 2026'), findsOneWidget);
    expect(find.textContaining('©'), findsNothing);
  });

  testWidgets('a video entry shows a link instead of an image', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _videoApodJson);

    expect(find.text('Today\'s entry is a video'), findsOneWidget);
    expect(find.text('Watch video'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a failed load shows the error state and Retry refetches', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _imageApodJson, failuresBeforeSuccess: 1);

    expect(find.text('Could not load the picture'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('NASA Science'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a transport failure shows the offline state', (
    WidgetTester tester,
  ) async {
    final ApiClient client = ApiClient(
      client: MockClient(
        (http.Request request) async =>
            throw http.ClientException('Connection refused', request.url),
      ),
      backoffBase: Duration.zero,
    );

    final FavoritesProvider favorites = FavoritesProvider();
    await favorites.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApodProvider>(
            create: (_) => ApodProvider(
              service: ApodService(apiKey: 'TEST', client: client),
            ),
          ),
          ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the favorite button saves and unsaves the picture', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider favorites = await pumpHome(
      tester,
      body: _imageApodJson,
    );

    expect(find.text('Save to favorites'), findsOneWidget);

    await tester.tap(find.text('Save to favorites'));
    await tester.pumpAndSettle();

    expect(favorites.contains(FavoriteType.apod, '2026-10-22'), isTrue);
    expect(find.text('Saved to favorites'), findsOneWidget);

    await tester.tap(find.text('Saved to favorites'));
    await tester.pumpAndSettle();

    expect(favorites.contains(FavoriteType.apod, '2026-10-22'), isFalse);
    expect(find.text('Save to favorites'), findsOneWidget);
  });

  testWidgets('an already saved picture opens in the saved state', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FavoritesProvider.storageKey: <String>[
        '{"id":"2026-10-22","type":"apod","title":"NASA Science","note":""}',
      ],
    });

    await pumpHome(tester, body: _imageApodJson);

    expect(find.text('Saved to favorites'), findsOneWidget);
  });
}
