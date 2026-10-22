import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:centralian_skywatch/models/iss_position.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/api_exception.dart';
import 'package:centralian_skywatch/services/iss_service.dart';

const String _issJson = '''
{
  "name": "iss",
  "id": 25544,
  "latitude": -32.046496529432,
  "longitude": 93.547317892411,
  "altitude": 425.17910452883,
  "velocity": 27570.895001261,
  "visibility": "eclipsed",
  "timestamp": 1792683638,
  "units": "kilometers"
}
''';

void main() {
  group('IssService', () {
    test('fetches and parses the position', () async {
      Uri? requested;
      final IssService service = IssService(
        client: ApiClient(
          client: MockClient((http.Request request) async {
            requested = request.url;
            return http.Response(_issJson, 200);
          }),
        ),
      );

      final IssPosition position = await service.fetchPosition();

      expect(position.latitude, closeTo(-32.046496529432, 1e-9));
      expect(position.speedKmh, closeTo(27570.895001261, 1e-9));
      expect(position.timestamp, isNotNull);
      expect(requested!.host, 'api.wheretheiss.at');
      expect(requested!.path, '/v1/satellites/25544');
    });

    test('propagates a server error', () async {
      final IssService service = IssService(
        client: ApiClient(
          client: MockClient(
            (http.Request request) async => http.Response('', 500),
          ),
        ),
      );

      await expectLater(
        service.fetchPosition(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
