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

  /// Total attempts for a rate-limited request, including the first one.
  final int maxAttempts;

  /// Delay before the first retry; it doubles on each further attempt.
  final Duration backoffBase;

  /// Performs a GET and decodes the JSON object in the response.
  ///
  /// Throws an [ApiException] subtype for every failure mode the app needs to
  /// tell apart: no connection, timeout, rate limit, server error, bad payload.
  Future<Map<String, dynamic>> getJson(Uri uri) async {
    for (int attempt = 1; ; attempt++) {
      final http.Response response = await _send(uri);

      if (response.statusCode == 429) {
        final Duration? retryAfter = _parseRetryAfter(response);
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryAfter ?? _backoffFor(attempt));
          continue;
        }
        throw RateLimitException(retryAfter: retryAfter);
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

  Map<String, dynamic> _decode(String body, int statusCode) {
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const ParseException();
      }

      // NASA and Launch Library report some failures inside a 200 body.
      final Object? error = decoded['error'] ?? decoded['detail'];
      if (error is String && error.isNotEmpty) {
        throw ServerException(statusCode: statusCode, message: error);
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ParseException();
    }
  }
}
