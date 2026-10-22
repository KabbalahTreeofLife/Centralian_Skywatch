/// Errors the API layer can raise.
///
/// The class is sealed so the UI can switch over every case and always show a
/// sensible message instead of a raw exception string.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Human-readable text that is safe to show in the UI.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The device has no usable connection.
class NoInternetException extends ApiException {
  const NoInternetException([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

/// The request took longer than the configured timeout.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([
    super.message = 'The server took too long to respond. Please try again.',
  ]);
}

/// The API rejected the request because of rate limiting (HTTP 429).
class RateLimitException extends ApiException {
  const RateLimitException({
    this.retryAfter,
    String message =
        'Too many requests right now. Please wait a moment and try again.',
  }) : super(message);

  /// How long the server asked us to wait, when it said so.
  final Duration? retryAfter;
}

/// The API answered with an error status.
class ServerException extends ApiException {
  const ServerException({required this.statusCode, String? message})
    : super(message ?? 'The server returned an error. Please try again.');

  final int statusCode;
}

/// The response body could not be read as the expected JSON.
class ParseException extends ApiException {
  const ParseException([
    super.message = 'The server sent data the app could not read.',
  ]);
}

/// A failure the app did not anticipate.
///
/// Providers use this so an unexpected bug still produces a readable message
/// instead of a red error screen.
class UnexpectedException extends ApiException {
  const UnexpectedException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
