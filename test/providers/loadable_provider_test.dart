import 'dart:async';

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

    test('a failure does not trigger an automatic retry loop', () async {
      // One call, one attempt. The provider must not spin on its own; a retry
      // only happens when something calls load() again.
      final _FakeProvider provider = _FakeProvider(
        () async => throw const ApiTimeoutException(),
      );

      await provider.load();

      expect(provider.calls, 1);
      expect(provider.status, LoadStatus.error);
    });

    test('a later load retries after a failure', () async {
      // The first attempt fails, as it does on a cold start with no network.
      // A plain load() afterwards must try again, otherwise the app is stuck on
      // the error screen until the user finds the Retry button.
      bool fail = true;
      final _FakeProvider provider = _FakeProvider(() async {
        if (fail) throw const NoInternetException();
        return 'value';
      });

      await provider.load();
      expect(provider.status, LoadStatus.error);

      fail = false;
      await provider.load();

      expect(provider.calls, 2);
      expect(provider.status, LoadStatus.success);
      expect(provider.data, 'value');
    });

    test('a successful load is still not refetched', () async {
      // The caching guarantee must survive the retry fix: once a load has
      // succeeded, plain load() calls stay cheap.
      final _FakeProvider provider = _FakeProvider(() async => 'value');

      await provider.load();
      await provider.load();
      await provider.load();

      expect(provider.calls, 1);
      expect(provider.status, LoadStatus.success);
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

    group('silent refresh', () {
      test('keeps the current status while the request is in flight', () async {
        final Completer<String> pending = Completer<String>();
        bool first = true;
        final _FakeProvider provider = _FakeProvider(() {
          if (first) {
            first = false;
            return Future<String>.value('v1');
          }
          return pending.future;
        });

        await provider.load();
        expect(provider.status, LoadStatus.success);

        final Future<void> refresh = provider.load(force: true, silent: true);

        // The screen must keep rendering the old value, not a loading view.
        expect(provider.status, LoadStatus.success);
        expect(provider.data, 'v1');

        pending.complete('v2');
        await refresh;

        expect(provider.status, LoadStatus.success);
        expect(provider.data, 'v2');
      });

      test('a failure keeps the last good value and status', () async {
        bool fail = false;
        final _FakeProvider provider = _FakeProvider(() async {
          if (fail) throw const NoInternetException();
          return 'v1';
        });

        await provider.load();
        fail = true;

        await provider.load(force: true, silent: true);

        expect(provider.status, LoadStatus.success);
        expect(provider.data, 'v1');
        expect(provider.error, isNull);
      });

      test('does not notify when a silent refresh fails', () async {
        bool fail = false;
        final _FakeProvider provider = _FakeProvider(() async {
          if (fail) throw const NoInternetException();
          return 'v1';
        });

        await provider.load();
        fail = true;

        int notifications = 0;
        provider.addListener(() => notifications++);

        await provider.load(force: true, silent: true);

        // Nothing changed, so there is nothing to rebuild.
        expect(notifications, 0);
      });

      test('notifies once when a silent refresh succeeds', () async {
        int value = 0;
        final _FakeProvider provider = _FakeProvider(() async => 'v${++value}');

        await provider.load();

        int notifications = 0;
        provider.addListener(() => notifications++);

        await provider.load(force: true, silent: true);

        expect(notifications, 1);
        expect(provider.data, 'v2');
      });

      test('a non-silent load still shows the loading status', () async {
        final Completer<String> pending = Completer<String>();
        bool first = true;
        final _FakeProvider provider = _FakeProvider(() {
          if (first) {
            first = false;
            return Future<String>.value('v1');
          }
          return pending.future;
        });

        await provider.load();

        final Future<void> refresh = provider.load(force: true);
        expect(provider.status, LoadStatus.loading);

        pending.complete('v2');
        await refresh;

        expect(provider.status, LoadStatus.success);
      });
    });
  });
}
