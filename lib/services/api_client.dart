import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin wrapper around [http.Client] that turns transport and status failures
/// into [ApiException]s.
///
/// One instance is shared by every service, so there is a single connection
/// pool to close when the app shuts down.
class ApiClient {
  ApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxAttempts = 3,
    this.backoffBase = const Duration(seconds: 1),
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// How long a single request may take before it is abandoned.
  final Duration timeout;

  /// Total attempts for a retryable failure, including the first one.
  final int maxAttempts;

  /// Delay before the first retry; it doubles on each further attempt.
  final Duration backoffBase;

  /// Performs a GET and decodes a JSON array of objects.
  ///
  /// NASA's APOD feed returns an array of recent entries rather than a single
  /// object, so it needs its own entry point. Entries that are not objects are
  /// skipped instead of failing the whole request.
  Future<List<Map<String, dynamic>>> getJsonList(Uri uri) async {
    final Object? decoded = await _getDecoded(uri);
    if (decoded is! List) throw const ParseException();

    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  /// Performs a GET and decodes the JSON object in the response.
  ///
  /// Throws an [ApiException] subtype for every failure mode the app needs to
  /// tell apart: no connection, timeout, rate limit, server error, bad payload.
  ///
  /// Rate limits, server errors and timeouts are retried, because all three are
  /// transient: NASA's APOD feed in particular alternates between a 500, a slow
  /// response and a good one, so a single attempt fails often enough to make
  /// the user press Retry repeatedly.
  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final Object? decoded = await _getDecoded(uri);
    if (decoded is! Map<String, dynamic>) throw const ParseException();
    return decoded;
  }

  /// Runs the request with retries and returns the decoded JSON body.
  Future<Object?> _getDecoded(Uri uri) async {
    for (int attempt = 1; ; attempt++) {
      final http.Response response;
      try {
        response = await _send(uri);
      } on ApiTimeoutException {
        // A timeout is worth another try, but only while attempts remain.
        if (attempt < maxAttempts) {
          await Future<void>.delayed(_backoffFor(attempt));
          continue;
        }
        rethrow;
      }

      if (response.statusCode == 429) {
        final Duration? retryAfter = _parseRetryAfter(response);
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryAfter ?? _backoffFor(attempt));
          continue;
        }
        throw RateLimitException(retryAfter: retryAfter);
      }

      if (_isRetryableServerError(response.statusCode) &&
          attempt < maxAttempts) {
        await Future<void>.delayed(_backoffFor(attempt));
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerException(
          statusCode: response.statusCode,
          message: _messageForStatus(response.statusCode),
        );
      }

      return _decode(response.body, response.statusCode);
    }
  }

  /// Whether a status is worth trying again.
  ///
  /// Only 5xx: a 4xx means the request itself is wrong, so repeating it would
  /// fail the same way and waste the caller's time.
  static bool _isRetryableServerError(int statusCode) => statusCode >= 500;

  /// Releases the underlying connection pool.
  void close() => _client.close();

  Future<http.Response> _send(Uri uri) async {
    try {
      return await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ApiTimeoutException();
    } on SocketException {
      throw const NoInternetException();
    } on http.ClientException {
      throw const NoInternetException();
    }
  }

  Duration _backoffFor(int attempt) => backoffBase * (1 << (attempt - 1));

  Duration? _parseRetryAfter(http.Response response) {
    final String? header = response.headers['retry-after'];
    if (header == null) return null;
    final int? seconds = int.tryParse(header.trim());
    return seconds == null ? null : Duration(seconds: seconds);
  }

  String _messageForStatus(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return 'The API rejected the request. Check your NASA_API_KEY.';
    }
    if (statusCode == 404) {
      return 'The requested data was not found.';
    }
    if (statusCode >= 500) {
      return 'The service is having trouble right now. Please try again later.';
    }
    return 'The server returned an error ($statusCode). Please try again.';
  }

  Object? _decode(String body, int statusCode) {
    try {
      final Object? decoded = jsonDecode(body);

      // NASA and Launch Library report some failures inside a 200 body.
      if (decoded is Map<String, dynamic>) {
        final Object? error = decoded['error'] ?? decoded['detail'];
        if (error is String && error.isNotEmpty) {
          throw ServerException(statusCode: statusCode, message: error);
        }
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ParseException();
    }
  }
}
