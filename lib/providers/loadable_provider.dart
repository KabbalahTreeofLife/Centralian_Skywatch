import 'package:flutter/foundation.dart';

import '../services/api_exception.dart';
import 'load_status.dart';

/// Base class for a provider that loads one value from an API.
///
/// It owns the loading/success/error cycle and caches the last response, so
/// switching tabs never triggers another request. Call [load] with
/// `force: true` to refresh.
abstract class LoadableProvider<T> extends ChangeNotifier {
  LoadStatus _status = LoadStatus.idle;
  T? _data;
  ApiException? _error;
  bool _hasLoaded = false;
  bool _inFlight = false;
  bool _disposed = false;

  /// Where the provider is in its request cycle.
  LoadStatus get status => _status;

  /// The most recent successful value, or null before the first success.
  T? get data => _data;

  /// The failure from the most recent attempt, or null when it succeeded.
  ApiException? get error => _error;

  bool get isLoading => _status == LoadStatus.loading;
  bool get hasData => _data != null;
  bool get hasError => _status == LoadStatus.error;

  /// Fetches the value once.
  ///
  /// A call is ignored while a request is already in flight, and after a
  /// successful load unless [force] is true. That is what keeps tab switches
  /// from refetching; the Retry button passes `force: true`.
  ///
  /// A failed attempt does not count as loaded, so a later plain [load] tries
  /// again. Without that, a cold start with no network would leave the app
  /// stuck on the error screen until the user found the Retry button.
  ///
  /// Pass [silent] for a refresh the user did not ask for, such as a polling
  /// screen. The status is left alone, so the UI keeps showing the last good
  /// value instead of flashing a loading view, and a failure is logged rather
  /// than replacing that value with an error screen.
  Future<void> load({bool force = false, bool silent = false}) async {
    if (_inFlight) return;
    if (_hasLoaded && !force) return;

    _inFlight = true;

    if (!silent) {
      _status = LoadStatus.loading;
      _error = null;
      _notify();
    }

    bool changed = false;
    try {
      _data = await fetch();
      _status = LoadStatus.success;
      _error = null;
      // Only a success is worth caching. A failure stays retryable.
      _hasLoaded = true;
      changed = true;
    } on ApiException catch (error) {
      if (silent) {
        // The user did not ask for this refresh, so keep the last good value
        // on screen and let the next poll try again.
        debugPrint('Background refresh failed: ${error.message}');
      } else {
        _error = error;
        _status = LoadStatus.error;
        changed = true;
      }
    } catch (error, stackTrace) {
      // A non-API failure is a bug rather than a network condition. Log it so
      // it is visible in DevTools, and still give the UI something to show.
      debugPrint('Unexpected provider failure: $error\n$stackTrace');
      if (!silent) {
        _error = const UnexpectedException();
        _status = LoadStatus.error;
        changed = true;
      }
    } finally {
      _inFlight = false;
    }

    if (changed) _notify();
  }

  /// Performs the actual request. Implemented by each concrete provider.
  @protected
  Future<T> fetch();

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
