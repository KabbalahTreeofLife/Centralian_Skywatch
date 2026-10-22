import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/iss_position.dart';
import 'package:centralian_skywatch/widgets/iss_readouts.dart';

IssPosition _position({
  double latitude = 51.64,
  double longitude = -0.28,
  double altitude = 420.5,
  double speedKmh = 27580.4,
}) => IssPosition(
  latitude: latitude,
  longitude: longitude,
  altitude: altitude,
  speedKmh: speedKmh,
);

Future<void> pumpReadouts(WidgetTester tester, IssPosition position) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: IssReadouts(position: position)),
    ),
  );
}

void main() {
  group('formatCoordinate', () {
    test('marks a positive latitude as north', () {
      expect(formatCoordinate(51.64, 'N', 'S'), '51.64° N');
    });

    test('marks a negative latitude as south', () {
      expect(formatCoordinate(-33.87, 'N', 'S'), '33.87° S');
    });

    test('marks a positive longitude as east', () {
      expect(formatCoordinate(139.69, 'E', 'W'), '139.69° E');
    });

    test('marks a negative longitude as west', () {
      expect(formatCoordinate(-0.28, 'E', 'W'), '0.28° W');
    });

    test('treats zero as positive rather than negative', () {
      expect(formatCoordinate(0, 'N', 'S'), '0.00° N');
    });

    test('always shows two decimal places', () {
      expect(formatCoordinate(5, 'N', 'S'), '5.00° N');
    });
  });

  group('IssReadouts', () {
    testWidgets('shows all four readouts', (WidgetTester tester) async {
      await pumpReadouts(tester, _position());

      expect(find.text('Latitude'), findsOneWidget);
      expect(find.text('Longitude'), findsOneWidget);
      expect(find.text('Altitude'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
    });

    testWidgets('formats the coordinates with hemispheres', (
      WidgetTester tester,
    ) async {
      await pumpReadouts(tester, _position());

      expect(find.text('51.64° N'), findsOneWidget);
      expect(find.text('0.28° W'), findsOneWidget);
    });

    testWidgets('shows altitude in km to one decimal', (
      WidgetTester tester,
    ) async {
      await pumpReadouts(tester, _position());

      expect(find.text('420.5 km'), findsOneWidget);
    });

    testWidgets('shows speed in km/h with no decimals', (
      WidgetTester tester,
    ) async {
      await pumpReadouts(tester, _position());

      expect(find.text('27580 km/h'), findsOneWidget);
    });

    testWidgets('handles southern and eastern coordinates', (
      WidgetTester tester,
    ) async {
      await pumpReadouts(
        tester,
        _position(latitude: -33.87, longitude: 139.69),
      );

      expect(find.text('33.87° S'), findsOneWidget);
      expect(find.text('139.69° E'), findsOneWidget);
    });
  });
}
