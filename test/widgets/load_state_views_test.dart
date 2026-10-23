import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/widgets/load_state_views.dart';

/// Wraps [child] in the minimum app needed to render it.
Future<void> pumpView(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('LoadingView', () {
    testWidgets('shows a spinner and its message', (WidgetTester tester) async {
      await pumpView(tester, const LoadingView(message: 'Loading launches…'));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading launches…'), findsOneWidget);
    });

    testWidgets('has a default message', (WidgetTester tester) async {
      await pumpView(tester, const LoadingView());

      expect(find.text('Loading…'), findsOneWidget);
    });
  });

  group('ErrorRetryView', () {
    testWidgets('shows the message and a Retry button', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        ErrorRetryView(message: 'No internet connection.', onRetry: () {}),
      );

      expect(find.text('No internet connection.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('calls onRetry when Retry is tapped', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await pumpView(
        tester,
        ErrorRetryView(message: 'Failed.', onRetry: () => retries++),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('shows an optional title above the message', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        ErrorRetryView(
          title: 'You are offline',
          message: 'Check your connection.',
          onRetry: () {},
        ),
      );

      expect(find.text('You are offline'), findsOneWidget);
      expect(find.text('Check your connection.'), findsOneWidget);
    });

    testWidgets('omits the title when none is given', (
      WidgetTester tester,
    ) async {
      await pumpView(
        tester,
        ErrorRetryView(message: 'Failed.', onRetry: () {}),
      );

      // Exactly two Texts: the message and the Retry label. A third would mean
      // an empty title row was rendered.
      expect(find.byType(Text), findsNWidgets(2));
      expect(find.text('Failed.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('uses the icon it is given', (WidgetTester tester) async {
      await pumpView(
        tester,
        ErrorRetryView(
          message: 'Failed.',
          icon: Icons.wifi_off,
          onRetry: () {},
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });
  });

  group('EmptyStateView', () {
    testWidgets('shows its title and message', (WidgetTester tester) async {
      await pumpView(
        tester,
        const EmptyStateView(
          title: 'No upcoming launches',
          message: 'Check back soon.',
        ),
      );

      expect(find.text('No upcoming launches'), findsOneWidget);
      expect(find.text('Check back soon.'), findsOneWidget);
    });

    testWidgets('works without a message', (WidgetTester tester) async {
      await pumpView(tester, const EmptyStateView(title: 'Nothing here'));

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('offers no Retry button, unlike the error state', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, const EmptyStateView(title: 'Nothing here'));

      expect(find.text('Retry'), findsNothing);
    });
  });
}
