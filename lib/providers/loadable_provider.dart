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
  /// A call is ignored while a request is already in flight, and after the
  /// first attempt has finished unless [force] is true. That is what keeps tab
  /// switches from refetching; the Retry button passes `force: true`.
  Future<void> load({bool force = false}) async {
    if (_status == LoadStatus.loading) return;
    if (_hasLoaded && !force) return;

    _hasLoaded = true;
    _status = LoadStatus.loading;
    _error = null;
    _notify();

    try {
      _data = await fetch();
      _status = LoadStatus.success;
    } on ApiException catch (error) {
      _error = error;
      _status = LoadStatus.error;
    } catch (error, stackTrace) {
      // A non-API failure is a bug rather than a network condition. Log it so
      // it is visible in DevTools, and still give the UI something to show.
      debugPrint('Unexpected provider failure: $error\n$stackTrace');
      _error = const UnexpectedException();
      _status = LoadStatus.error;
    }

    _notify();
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
