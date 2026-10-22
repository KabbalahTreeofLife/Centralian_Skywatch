import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:centralian_skywatch/models/launch.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/api_exception.dart';
import 'package:centralian_skywatch/services/launch_service.dart';

const String _launchJson = '''
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "a",
      "name": "Falcon 9 Block 5 | Starlink Group 15-15",
      "status": {"id": 1, "name": "Go for Launch", "description": "Confirmed."},
      "net": "2026-10-22T22:51:18Z",
      "lsp_name": "SpaceX",
      "mission_type": "Communications",
      "pad": "Space Launch Complex 4E",
      "location": "Vandenberg SFB, CA, USA",
      "image": "https://example.test/a.png"
    },
    {
      "id": "b",
      "name": "Ariane 62 | Demo",
      "status": {"id": 2, "name": "TBD", "description": "To be determined."},
      "net": "2026-11-01T09:00:00Z",
      "lsp_name": "Arianespace",
      "mission_type": "Test Flight",
      "pad": "ELA-4",
      "location": "Kourou, French Guiana",
      "image": null
    }
  ]
}
''';

void main() {
  group('LaunchService', () {
    test('parses the results list', () async {
      Uri? requested;
      final LaunchService service = LaunchService(
        client: ApiClient(
          client: MockClient((http.Request request) async {
            requested = request.url;
            return http.Response(_launchJson, 200);
          }),
        ),
      );

      final List<Launch> launches = await service.fetchUpcoming(limit: 5);

      expect(launches, hasLength(2));
      expect(launches.first.name, 'Falcon 9 Block 5 | Starlink Group 15-15');
      expect(launches.first.agency, 'SpaceX');
      expect(launches.last.imageUrl, isNull);
      expect(requested!.queryParameters['mode'], 'list');
      expect(requested!.queryParameters['limit'], '5');
    });

    test('returns an empty list when there are no launches', () async {
      final LaunchService service = LaunchService(
        client: ApiClient(
          client: MockClient(
            (http.Request request) async =>
                http.Response('{"count": 0, "results": []}', 200),
          ),
        ),
      );

      expect(await service.fetchUpcoming(), isEmpty);
    });

    test('returns an empty list when results is missing', () async {
      final LaunchService service = LaunchService(
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response('{"count": 0}', 200),
          ),
        ),
      );

      expect(await service.fetchUpcoming(), isEmpty);
    });

    test('propagates a rate limit', () async {
      final LaunchService service = LaunchService(
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response('', 429),
          ),
          maxAttempts: 2,
          backoffBase: Duration.zero,
        ),
      );

      await expectLater(
        service.fetchUpcoming(),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
