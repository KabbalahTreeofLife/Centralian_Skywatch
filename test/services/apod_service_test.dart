import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:centralian_skywatch/models/apod.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/api_exception.dart';
import 'package:centralian_skywatch/services/apod_service.dart';

const String _apodJson = '''
{
  "date": "2026-10-22",
  "explanation": "Star light, star bright.",
  "hdurl": "https://example.test/hd.jpg",
  "media_type": "image",
  "service_version": "v1",
  "title": "NASA Science",
  "url": "https://example.test/std.jpg"
}
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

      expect(apod.title, 'NASA Science');
      expect(apod.isImage, isTrue);
      expect(apod.date, '2026-10-22');
      expect(requested!.host, 'api.nasa.gov');
      expect(requested!.path, '/planetary/apod');
      expect(requested!.queryParameters['api_key'], 'TEST_KEY');
    });

    test('propagates a server error', () async {
      final ApodService service = ApodService(
        apiKey: 'TEST_KEY',
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response('', 503),
          ),
        ),
      );

      await expectLater(service.fetchToday(), throwsA(isA<ServerException>()));
    });
  });
}
