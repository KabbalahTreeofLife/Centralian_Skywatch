import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:centralian_skywatch/providers/iss_provider.dart';
import 'package:centralian_skywatch/screens/iss_screen.dart';
import 'package:centralian_skywatch/services/api_client.dart';
import 'package:centralian_skywatch/services/iss_service.dart';
import 'package:centralian_skywatch/widgets/iss_readouts.dart';
import 'package:centralian_skywatch/widgets/load_state_views.dart';

/// A real response shape from Where the ISS at?.
String _body({
  double latitude = 51.64,
  double longitude = -0.28,
  double altitude = 420.5,
  double velocity = 27580.4,
}) => jsonEncode(<String, dynamic>{
  'name': 'iss',
  'id': 25544,
  'latitude': latitude,
  'longitude': longitude,
  'altitude': altitude,
  'velocity': velocity,
  'visibility': 'daylight',
  'footprint': 4530.5,
  'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  'daynum': 2460000.5,
  'solar_lat': 10.0,
  'solar_lon': 20.0,
  'units': 'kilometers',
});

/// Pumps the ISS screen over a client that answers with [body].
///
/// Uses explicit pumps rather than `pumpAndSettle`: the screen runs a
/// 30-second auto-refresh timer, so settling would never finish.
Future<void> pumpIss(
  WidgetTester tester, {
  required String body,
  int statusCode = 200,
  int failuresBeforeSuccess = 0,
  int failureStatusCode = 500,
}) async {
  int calls = 0;
  final ApiClient client = ApiClient(
    client: MockClient((http.Request request) async {
      calls++;
      if (calls <= failuresBeforeSuccess) {
        return http.Response('', failureStatusCode);
      }
      return http.Response(body, statusCode);
    }),
    backoffBase: Duration.zero,
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<IssProvider>(
      create: (_) => IssProvider(service: IssService(client: client)),
      child: const MaterialApp(home: IssScreen()),
    ),
  );

  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('shows a loading view before the response arrives', (
    WidgetTester tester,
  ) async {
    final Completer<http.Response> pending = Completer<http.Response>();
    final ApiClient client = ApiClient(
      client: MockClient((_) => pending.future),
      backoffBase: Duration.zero,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<IssProvider>(
        create: (_) => IssProvider(service: IssService(client: client)),
        child: const MaterialApp(home: IssScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.text('Locating the station…'), findsOneWidget);

    // Complete the request so no timer is left pending at teardown.
    pending.complete(http.Response(_body(), 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('shows the readouts once loaded', (WidgetTester tester) async {
    await pumpIss(tester, body: _body());

    expect(find.byType(IssReadouts), findsOneWidget);
    expect(find.text('51.64° N'), findsOneWidget);
    expect(find.text('0.28° W'), findsOneWidget);
    expect(find.text('420.5 km'), findsOneWidget);
    expect(find.text('27580 km/h'), findsOneWidget);
  });

  testWidgets('shows the update time', (WidgetTester tester) async {
    await pumpIss(tester, body: _body());

    expect(find.textContaining('Updated '), findsOneWidget);
  });

  testWidgets('shows the error state with Retry when the request fails', (
    WidgetTester tester,
  ) async {
    await pumpIss(
      tester,
      body: _body(),
      failuresBeforeSuccess: 99,
      failureStatusCode: 404,
    );

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Retry reloads and shows the readouts', (
    WidgetTester tester,
  ) async {
    await pumpIss(
      tester,
      body: _body(),
      failuresBeforeSuccess: 1,
      failureStatusCode: 404,
    );

    expect(find.byType(ErrorRetryView), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(IssReadouts), findsOneWidget);
  });

  testWidgets('the refresh button reloads the position', (
    WidgetTester tester,
  ) async {
    await pumpIss(tester, body: _body(latitude: 10.0, longitude: 20.0));

    expect(find.text('10.00° N'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The same body is returned, so the readouts are still present and the
    // screen did not fall into an error state.
    expect(find.byType(IssReadouts), findsOneWidget);
    expect(find.byType(ErrorRetryView), findsNothing);
  });

  testWidgets('auto-refreshes on its own', (WidgetTester tester) async {
    int calls = 0;
    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        calls++;
        return http.Response(_body(), 200);
      }),
      backoffBase: Duration.zero,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<IssProvider>(
        create: (_) => IssProvider(service: IssService(client: client)),
        child: const MaterialApp(home: IssScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(calls, 1);

    // Advance past one auto-refresh interval.
    await tester.pump(IssScreen.refreshInterval);
    await tester.pump(const Duration(milliseconds: 50));

    expect(calls, 2);
  });

  testWidgets('auto-refresh updates in place without a loading view', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    Completer<http.Response>? pending;
    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        calls++;
        if (calls == 1) {
          return http.Response(_body(latitude: 10.0), 200);
        }
        pending = Completer<http.Response>();
        return pending!.future;
      }),
      backoffBase: Duration.zero,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<IssProvider>(
        create: (_) => IssProvider(service: IssService(client: client)),
        child: const MaterialApp(home: IssScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('10.00° N'), findsOneWidget);

    // The timer fires while the response is still pending.
    await tester.pump(IssScreen.refreshInterval);
    await tester.pump();

    expect(calls, 2);
    expect(find.byType(LoadingView), findsNothing);
    expect(find.text('10.00° N'), findsOneWidget);

    pending!.complete(http.Response(_body(latitude: 20.0), 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('20.00° N'), findsOneWidget);
  });

  testWidgets('the refresh button shows the loading view', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    Completer<http.Response>? pending;
    final ApiClient client = ApiClient(
      client: MockClient((http.Request request) async {
        calls++;
        if (calls == 1) {
          return http.Response(_body(), 200);
        }
        pending = Completer<http.Response>();
        return pending!.future;
      }),
      backoffBase: Duration.zero,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<IssProvider>(
        create: (_) => IssProvider(service: IssService(client: client)),
        child: const MaterialApp(home: IssScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(IssReadouts), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);

    pending!.complete(http.Response(_body(), 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(IssReadouts), findsOneWidget);
  });
}
