import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/iss_position.dart';

/// A real response captured from api.wheretheiss.at.
const String _sampleJson = '''
{
  "name": "iss",
  "id": 25544,
  "latitude": -32.046496529432,
  "longitude": 93.547317892411,
  "altitude": 425.17910452883,
  "velocity": 27570.895001261,
  "visibility": "eclipsed",
  "footprint": 4533.7191200181,
  "timestamp": 1792683638,
  "daynum": 2461336.1532176,
  "solar_lat": -11.206327504111,
  "solar_lon": 300.95021576576,
  "units": "kilometers"
}
''';

void main() {
  group('IssPosition.fromJson', () {
    test('parses a real ISS response', () {
      final IssPosition position = IssPosition.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(position.latitude, closeTo(-32.046496529432, 1e-9));
      expect(position.longitude, closeTo(93.547317892411, 1e-9));
      expect(position.altitude, closeTo(425.17910452883, 1e-9));
      expect(position.speedKmh, closeTo(27570.895001261, 1e-9));
      expect(
        position.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1792683638 * 1000, isUtc: true),
      );
      expect(position.timestamp!.isUtc, isTrue);
    });

    test('survives missing fields', () {
      final IssPosition position = IssPosition.fromJson(<String, dynamic>{});

      expect(position.latitude, 0);
      expect(position.longitude, 0);
      expect(position.altitude, 0);
      expect(position.speedKmh, 0);
      expect(position.timestamp, isNull);
    });

    test('accepts numeric strings', () {
      final IssPosition position = IssPosition.fromJson(<String, dynamic>{
        'latitude': '-32.5',
        'longitude': '93.5',
        'altitude': '425',
        'velocity': '27570',
        'timestamp': '1792683638',
      });

      expect(position.latitude, -32.5);
      expect(position.longitude, 93.5);
      expect(position.altitude, 425);
      expect(position.speedKmh, 27570);
      expect(position.timestamp, isNotNull);
    });
  });
}
