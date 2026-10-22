import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/api_exception.dart';

final Uri _uri = Uri.parse('https://example.test/data');

ApiClient _clientReturning(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 15),
  int maxAttempts = 3,
}) {
  return ApiClient(
    client: MockClient(handler),
    timeout: timeout,
    maxAttempts: maxAttempts,
    backoffBase: Duration.zero,
  );
}

void main() {
  group('ApiClient.getJson', () {
    test('decodes a successful JSON object', () async {
      final ApiClient api = _clientReturning(
        (http.Request request) async => http.Response('{"ok": true}', 200),
      );

      expect(await api.getJson(_uri), <String, dynamic>{'ok': true});
    });

    test('maps a 500 to ServerException after exhausting retries', () async {
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        return http.Response('', 500);
      });

      await expectLater(
        api.getJson(_uri),
        throwsA(
          isA<ServerException>().having(
            (ServerException e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(calls, 3);
    });

    test('retries a 500 and then succeeds', () async {
      // NASA's APOD feed alternates between a 500 and a good response, so a
      // single attempt fails about half the time.
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        if (calls < 3) return http.Response('', 500);
        return http.Response('{"ok": true}', 200);
      });

      expect(await api.getJson(_uri), <String, dynamic>{'ok': true});
      expect(calls, 3);
    });

    test('does not retry a 4xx', () async {
      // A 4xx means the request is wrong, so repeating it would fail the same
      // way and waste the caller's time.
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        return http.Response('', 404);
      });

      await expectLater(api.getJson(_uri), throwsA(isA<ServerException>()));
      expect(calls, 1);
    });

    test('maps 401 to a message about the API key', () async {
      final ApiClient api = _clientReturning(
        (http.Request request) async => http.Response('', 401),
      );

      await expectLater(
        api.getJson(_uri),
        throwsA(
          isA<ServerException>().having(
            (ServerException e) => e.message,
            'message',
            contains('NASA_API_KEY'),
          ),
        ),
      );
    });

    test('retries a 429 and then succeeds', () async {
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        if (calls < 3) return http.Response('', 429);
        return http.Response('{"ok": true}', 200);
      });

      expect(await api.getJson(_uri), <String, dynamic>{'ok': true});
      expect(calls, 3);
    });

    test('gives up after maxAttempts and throws RateLimitException', () async {
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        return http.Response('', 429);
      });

      await expectLater(api.getJson(_uri), throwsA(isA<RateLimitException>()));
      expect(calls, 3);
    });

    test('honours Retry-After on a 429', () async {
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            '',
            429,
            headers: <String, String>{'retry-after': '0'},
          );
        }
        return http.Response('{"ok": true}', 200);
      });

      expect(await api.getJson(_uri), <String, dynamic>{'ok': true});
      expect(calls, 2);
    });

    test('maps SocketException to NoInternetException', () async {
      final ApiClient api = _clientReturning(
        (http.Request request) async => throw const SocketException('offline'),
      );

      await expectLater(api.getJson(_uri), throwsA(isA<NoInternetException>()));
    });

    test('maps a slow response to ApiTimeoutException', () async {
      final ApiClient api = _clientReturning((http.Request request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      }, timeout: const Duration(milliseconds: 20));

      await expectLater(api.getJson(_uri), throwsA(isA<ApiTimeoutException>()));
    });

    test('retries a timeout and then succeeds', () async {
      // A slow response is as transient as a 500, so it is worth another try.
      int calls = 0;
      final ApiClient api = _clientReturning((http.Request request) async {
        calls++;
        if (calls < 3) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return http.Response('{"ok": true}', 200);
      }, timeout: const Duration(milliseconds: 20));

      expect(await api.getJson(_uri), <String, dynamic>{'ok': true});
      expect(calls, 3);
    });

    test('maps malformed JSON to ParseException', () async {
      final ApiClient api = _clientReturning(
        (http.Request request) async => http.Response('not json', 200),
      );

      await expectLater(api.getJson(_uri), throwsA(isA<ParseException>()));
    });

    test('maps a JSON array to ParseException', () async {
      final ApiClient api = _clientReturning(
        (http.Request request) async => http.Response('[1,2,3]', 200),
      );

      await expectLater(api.getJson(_uri), throwsA(isA<ParseException>()));
    });

    test('surfaces an error field inside a 200 body', () async {
      final ApiClient api = _clientReturning(
        (http.Request request) async =>
            http.Response('{"error": "invalid api_key"}', 200),
      );

      await expectLater(
        api.getJson(_uri),
        throwsA(
          isA<ServerException>().having(
            (ServerException e) => e.message,
            'message',
            'invalid api_key',
          ),
        ),
      );
    });
  });
}
