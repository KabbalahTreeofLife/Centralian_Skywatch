import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/providers/load_status.dart';
import 'package:centralian_skywatch/providers/loadable_provider.dart';
import 'package:centralian_skywatch/services/api_exception.dart';

/// Minimal concrete provider so the base class can be tested on its own.
class _FakeProvider extends LoadableProvider<String> {
  _FakeProvider(this._result);

  final Future<String> Function() _result;
  int calls = 0;

  @override
  Future<String> fetch() {
    calls++;
    return _result();
  }
}

void main() {
  group('LoadableProvider', () {
    test('starts idle with no data and no error', () {
      final _FakeProvider provider = _FakeProvider(() async => 'value');

      expect(provider.status, LoadStatus.idle);
      expect(provider.data, isNull);
      expect(provider.error, isNull);
      expect(provider.hasData, isFalse);
      expect(provider.hasError, isFalse);
    });

    test('moves through loading to success', () async {
      final _FakeProvider provider = _FakeProvider(() async => 'value');

      final Future<void> pending = provider.load();
      expect(provider.status, LoadStatus.loading);
      expect(provider.isLoading, isTrue);

      await pending;
      expect(provider.status, LoadStatus.success);
      expect(provider.data, 'value');
      expect(provider.error, isNull);
      expect(provider.calls, 1);
    });

    test('captures an ApiException and keeps its message', () async {
      final _FakeProvider provider = _FakeProvider(
        () async => throw const NoInternetException(),
      );

      await provider.load();

      expect(provider.status, LoadStatus.error);
      expect(provider.hasError, isTrue);
      expect(provider.error, isA<NoInternetException>());
      expect(provider.data, isNull);
    });

    test('a second load does not refetch', () async {
      final _FakeProvider provider = _FakeProvider(() async => 'value');

      await provider.load();
      await provider.load();
      await provider.load();

      expect(provider.calls, 1);
    });

    test('a failed load is not retried automatically', () async {
      final _FakeProvider provider = _FakeProvider(
        () async => throw const ApiTimeoutException(),
      );

      await provider.load();
      await provider.load();

      expect(provider.calls, 1);
      expect(provider.status, LoadStatus.error);
    });

    test('force reloads and replaces the data', () async {
      int value = 0;
      final _FakeProvider provider = _FakeProvider(() async => 'v${++value}');

      await provider.load();
      expect(provider.data, 'v1');

      await provider.load(force: true);
      expect(provider.data, 'v2');
      expect(provider.calls, 2);
    });

    test('ignores a load while one is already in flight', () async {
      final _FakeProvider provider = _FakeProvider(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'value';
      });

      final Future<void> first = provider.load();
      final Future<void> second = provider.load();
      await Future.wait(<Future<void>>[first, second]);

      expect(provider.calls, 1);
      expect(provider.status, LoadStatus.success);
    });

    test(
      'notifies listeners when loading starts and when it finishes',
      () async {
        final _FakeProvider provider = _FakeProvider(() async => 'value');
        int notifications = 0;
        provider.addListener(() => notifications++);

        await provider.load();

        expect(notifications, 2);
      },
    );

    test('does not notify after dispose', () async {
      final _FakeProvider provider = _FakeProvider(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'value';
      });

      final Future<void> pending = provider.load();
      provider.dispose();
      await pending;

      // Reaching here without a "used after dispose" error is the assertion.
      expect(provider.status, LoadStatus.success);
    });
  });
}
