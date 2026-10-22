import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:centralian_skywatch/providers/apod_provider.dart';
import 'package:centralian_skywatch/providers/iss_provider.dart';
import 'package:centralian_skywatch/providers/launch_provider.dart';
import 'package:centralian_skywatch/providers/load_status.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/api_exception.dart';
import 'package:centralian_skywatch/services/apod_service.dart';
import 'package:centralian_skywatch/services/iss_service.dart';
import 'package:centralian_skywatch/services/launch_service.dart';

const String _apodJson = '''
{"date":"2026-10-22","title":"NASA Science","media_type":"image","url":"https://example.test/a.jpg"}
''';

const String _launchJson = '''
{"count":1,"results":[{"id":"a","name":"Falcon 9 | Test","status":{"name":"Go"},"net":"2026-10-22T22:51:18Z","lsp_name":"SpaceX"}]}
''';

const String _issJson = '''
{"latitude":1.5,"longitude":2.5,"velocity":27570,"timestamp":1792683638}
''';

ApiClient _client(String body, {int status = 200}) => ApiClient(
  client: MockClient(
    (http.Request request) async => http.Response(body, status),
  ),
  backoffBase: Duration.zero,
);

void main() {
  group('ApodProvider', () {
    test('exposes the parsed picture', () async {
      final ApodProvider provider = ApodProvider(
        service: ApodService(apiKey: 'TEST', client: _client(_apodJson)),
      );

      await provider.load();

      expect(provider.status, LoadStatus.success);
      expect(provider.data?.title, 'NASA Science');
    });

    test('exposes a server error', () async {
      final ApodProvider provider = ApodProvider(
        service: ApodService(apiKey: 'TEST', client: _client('', status: 500)),
      );

      await provider.load();

      expect(provider.status, LoadStatus.error);
      expect(provider.error, isA<ServerException>());
    });
  });

  group('LaunchProvider', () {
    test('exposes the parsed launches', () async {
      final LaunchProvider provider = LaunchProvider(
        service: LaunchService(client: _client(_launchJson)),
      );

      await provider.load();

      expect(provider.status, LoadStatus.success);
      expect(provider.data, hasLength(1));
      expect(provider.data!.first.agency, 'SpaceX');
    });

    test('exposes an empty list as success', () async {
      final LaunchProvider provider = LaunchProvider(
        service: LaunchService(client: _client('{"count":0,"results":[]}')),
      );

      await provider.load();

      expect(provider.status, LoadStatus.success);
      expect(provider.data, isEmpty);
    });
  });

  group('IssProvider', () {
    test('exposes the parsed position', () async {
      final IssProvider provider = IssProvider(
        service: IssService(client: _client(_issJson)),
      );

      await provider.load();

      expect(provider.status, LoadStatus.success);
      expect(provider.data?.latitude, 1.5);
    });

    test('exposes a rate limit', () async {
      final IssProvider provider = IssProvider(
        service: IssService(
          client: ApiClient(
            client: MockClient(
              (http.Request request) async => http.Response('', 429),
            ),
            maxAttempts: 2,
            backoffBase: Duration.zero,
          ),
        ),
      );

      await provider.load();

      expect(provider.status, LoadStatus.error);
      expect(provider.error, isA<RateLimitException>());
    });
  });
}
