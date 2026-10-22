import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/apod.dart';

/// A real APOD response captured from api.nasa.gov.
const String _sampleJson = '''
{
  "date": "2026-10-22",
  "explanation": "Star light, star bright: is there a green star out tonight?",
  "hdurl": "https://science.nasa.gov/wp-content/themes/nasa-child/assets/images/nasa-logo@2x.png",
  "media_type": "image",
  "service_version": "v1",
  "title": "NASA Science",
  "url": "https://science.nasa.gov/wp-content/themes/nasa-child/assets/images/nasa-logo@2x.png"
}
''';

void main() {
  group('Apod.fromJson', () {
    test('parses a real APOD response', () {
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.title, 'NASA Science');
      expect(apod.explanation, contains('Star light'));
      expect(apod.mediaType, 'image');
      expect(apod.isImage, isTrue);
      expect(apod.url, startsWith('https://'));
      expect(apod.hdUrl, startsWith('https://'));
      expect(apod.date, '2026-10-22');
      // NASA-owned images carry no copyright field.
      expect(apod.copyright, isNull);
    });

    test('handles a video entry without hdurl or copyright', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'A video',
        'explanation': 'A description.',
        'url': 'https://www.youtube.com/embed/abc123',
        'media_type': 'video',
      });

      expect(apod.isImage, isFalse);
      expect(apod.hdUrl, isNull);
      expect(apod.copyright, isNull);
      expect(apod.date, '');
    });

    test('survives an empty object', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{});

      expect(apod.title, 'Astronomy Picture of the Day');
      expect(apod.mediaType, 'image');
      expect(apod.url, '');
      expect(apod.hdUrl, isNull);
    });
  });
}
