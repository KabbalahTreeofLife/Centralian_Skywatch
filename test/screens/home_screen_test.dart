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

/// A real entry, in the array shape the feed returns.
const String _imageApodJson =
    '[{"date":"2026-10-22","title":"The First Green Star","media_type":"image",'
    '"permalink":"https://science.nasa.gov/image-article/apod-2026-october-22/",'
    '"hdurl":"https://example.test/a-hd.jpg",'
    '"explanation":"<strong>Explanation:</strong> A picture of something far away.",'
    '"credit":"Jane Doe"}]';

/// A video entry. The feed still sends a still frame in `hdurl`.
const String _videoApodJson =
    '[{"date":"2026-10-21","title":"A Launch Video","media_type":"video",'
    '"permalink":"https://science.nasa.gov/image-article/apod-2026-october-21/",'
    '"hdurl":"https://example.test/video-still.jpg",'
    '"explanation":"A video entry."}]';

/// An entry with no picture at all.
const String _noImageApodJson =
    '[{"date":"2026-10-20","title":"No Picture Today","media_type":"image",'
    '"permalink":"https://science.nasa.gov/image-article/apod-2026-october-20/",'
    '"explanation":"The feed sent no image for this entry."}]';

/// Pumps the Home screen over a client that answers APOD requests with [body].
Future<FavoritesProvider> pumpHome(
  WidgetTester tester, {
  required String body,
  int statusCode = 200,
  int failuresBeforeSuccess = 0,
  int failureStatusCode = 500,
}) async {
  int calls = 0;
  final ApiClient client = ApiClient(
    client: MockClient((http.Request request) async {
      calls++;
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

    expect(find.text('The First Green Star'), findsOneWidget);
    expect(find.textContaining('22 October 2026'), findsOneWidget);
    expect(find.textContaining('Jane Doe'), findsOneWidget);
    expect(
      find.textContaining('A picture of something far away.'),
      findsOneWidget,
    );
  });

  testWidgets('omits the credit when NASA owns the picture', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _videoApodJson);

    expect(find.text('21 October 2026'), findsOneWidget);
    expect(find.textContaining('©'), findsNothing);
  });

  testWidgets('a video entry shows its still frame and a watch button', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _videoApodJson);

    // The feed sends a poster frame for videos, so the picture is shown.
    expect(find.text('A Launch Video'), findsOneWidget);
    expect(find.text('Watch video'), findsOneWidget);
  });

  testWidgets('an entry with no picture shows a notice', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _noImageApodJson);

    expect(find.text('No picture for this entry'), findsOneWidget);
    expect(find.text('No Picture Today'), findsOneWidget);
  });

  testWidgets('the explanation is shown without HTML', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, body: _imageApodJson);

    expect(find.textContaining('<strong>'), findsNothing);
    expect(find.textContaining('A picture of something far away'), findsWidgets);
  });

  testWidgets('a failed load shows the error state and Retry refetches', (
    WidgetTester tester,
  ) async {
    // A 404 is not retried, so the first load fails and the error state shows.
    await pumpHome(
      tester,
      body: _imageApodJson,
      failuresBeforeSuccess: 1,
      failureStatusCode: 404,
    );

    expect(find.text('Could not load the picture'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('The First Green Star'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a flapping 500 is absorbed without showing an error', (
    WidgetTester tester,
  ) async {
    // NASA's feed alternates between a 500 and a good response. The client
    // retries, so the user never sees the error screen.
    await pumpHome(tester, body: _imageApodJson, failuresBeforeSuccess: 2);

    expect(find.text('Could not load the picture'), findsNothing);
    expect(find.text('The First Green Star'), findsOneWidget);
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
        '{"id":"2026-10-22","type":"apod","title":"The First Green Star","note":""}',
      ],
    });

    await pumpHome(tester, body: _imageApodJson);

    expect(find.text('Saved to favorites'), findsOneWidget);
  });

  testWidgets('the picture is saved under its real title', (
    WidgetTester tester,
  ) async {
    final FavoritesProvider favorites = await pumpHome(
      tester,
      body: _imageApodJson,
    );

    await tester.tap(find.text('Save to favorites'));
    await tester.pumpAndSettle();

    expect(favorites.items.single.title, 'The First Green Star');
  });
}
