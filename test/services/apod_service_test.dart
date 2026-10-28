import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:centralian_skywatch/models/apod.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/api_exception.dart';
import 'package:centralian_skywatch/services/apod_service.dart';

/// The feed returns an array of recent entries, newest first.
const String _apodJson = '''
[
  {
    "date": "2026-10-22",
    "title": "The First Green Star, WD J1330+6435",
    "permalink": "https://science.nasa.gov/image-article/apod-2026-october-22/",
    "media_type": "image",
    "explanation": "<strong>Explanation:</strong> Star light, star bright.",
    "credit": "Mark A. Garlick",
    "url": "https://science.nasa.gov/image-article/apod-2026-october-22/",
    "hdurl": "https://assets.science.nasa.gov/dynamicimage/green_wd.jpg"
  },
  {
    "date": "2026-10-21",
    "title": "New Ghosts Revealed in Cassiopeia",
    "media_type": "image",
    "explanation": "An older entry.",
    "hdurl": "https://assets.science.nasa.gov/dynamicimage/ghosts.jpg"
  }
]
''';

void main() {
  group('ApodService', () {
    test("fetches and parses today's picture", () async {
      Uri? requested;
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient((http.Request request) async {
            requested = request.url;
            return http.Response(_apodJson, 200);
          }),
        ),
      );

      final Apod apod = await service.fetchToday();

      expect(apod.title, 'The First Green Star, WD J1330+6435');
      expect(apod.date, '2026-10-22');
      expect(apod.hasImage, isTrue);
      expect(requested!.host, 'science.nasa.gov');
      expect(requested!.path, '/wp-json/wp/v2/apod-basic/');
      expect(requested!.queryParameters['api_key'], 'TEST_KEY');
    });

    test('takes the newest entry from the array', () async {
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response(_apodJson, 200),
          ),
        ),
      );

      final Apod apod = await service.fetchToday();

      // The second entry is older, so it must not be the one returned.
      expect(apod.date, '2026-10-22');
      expect(apod.title, isNot('New Ghosts Revealed in Cassiopeia'));
    });

    test('an empty feed is a parse failure, not an empty picture', () async {
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response('[]', 200),
          ),
        ),
      );

      await expectLater(service.fetchToday(), throwsA(isA<ParseException>()));
    });

    test('propagates a server error', () async {
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response('', 404),
          ),
        ),
      );

      await expectLater(service.fetchToday(), throwsA(isA<ServerException>()));
    });

    test('extracts a NASA-hosted video source from the APOD HTML', () async {
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient((http.Request request) async {
            if (request.url.path.endsWith('/html')) {
              return http.Response(
                '<video><source src="https://assets.science.nasa.gov/video.mp4" '
                'type="video/mp4"></video>',
                200,
              );
            }
            return http.Response('''
              [{
                "date":"2026-10-28",
                "title":"Video APOD",
                "media_type":"video",
                "hdurl":"https://assets.science.nasa.gov/poster.jpg",
                "basic_html_url":"https://science.nasa.gov/wp-json/apod/261028/html"
              }]
              ''', 200);
          }),
        ),
      );

      final Apod apod = await service.fetchToday();

      expect(apod.isVideo, isTrue);
      expect(apod.videoUrl, 'https://assets.science.nasa.gov/video.mp4');
    });

    test('ignores a video source hosted outside NASA', () async {
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient((http.Request request) async {
            if (request.url.path.endsWith('/html')) {
              return http.Response(
                '<video><source src="https://attacker.example/video.mp4"></video>',
                200,
              );
            }
            return http.Response('''
              [{
                "date":"2026-10-28",
                "title":"Video APOD",
                "media_type":"video",
                "basic_html_url":"https://science.nasa.gov/wp-json/apod/261028/html"
              }]
              ''', 200);
          }),
        ),
      );

      final Apod apod = await service.fetchToday();

      expect(apod.isVideo, isTrue);
      expect(apod.videoUrl, isNull);
    });
  });
}
