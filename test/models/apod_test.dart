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

  group('placeholder detection', () {
    test('flags the site-logo payload NASA serves when it has no picture', () {
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.isPlaceholder, isTrue);
      expect(apod.imageUrl, isNull);
      // The date is a better label than the site name.
      expect(apod.displayTitle, '2026-10-22');
    });

    test('accepts a real APOD image', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'date': '2026-10-22',
        'title': 'The First Green Star, WD J1330+6435',
        'explanation': 'A description.',
        'media_type': 'image',
        'url': 'https://apod.nasa.gov/apod/image/2610/green_wd.jpg',
        'hdurl': 'https://apod.nasa.gov/apod/image/2610/green_wd_hd.jpg',
      });

      expect(apod.isPlaceholder, isFalse);
      expect(
        apod.imageUrl,
        'https://apod.nasa.gov/apod/image/2610/green_wd_hd.jpg',
      );
      expect(apod.displayTitle, 'The First Green Star, WD J1330+6435');
    });

    test('prefers hdurl but falls back to url', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'date': '2026-10-22',
        'title': 'No HD today',
        'media_type': 'image',
        'url': 'https://apod.nasa.gov/apod/image/2610/only.jpg',
      });

      expect(apod.imageUrl, 'https://apod.nasa.gov/apod/image/2610/only.jpg');
    });

    test('a video entry has no image url', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'A video',
        'media_type': 'video',
        'url': 'https://www.youtube.com/embed/abc123',
      });

      expect(apod.imageUrl, isNull);
      expect(apod.isPlaceholder, isFalse);
    });

    test('flags a theme asset even when the title looks real', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'date': '2026-10-22',
        'title': 'A real looking title',
        'media_type': 'image',
        'url': 'https://science.nasa.gov/wp-content/themes/nasa-child/x.png',
      });

      expect(apod.isPlaceholder, isTrue);
      expect(apod.imageUrl, isNull);
    });

    test('an empty url is not treated as a placeholder', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'date': '2026-10-22',
        'title': 'Missing url',
        'media_type': 'image',
      });

      expect(apod.isPlaceholder, isFalse);
      expect(apod.imageUrl, isNull);
    });
  });
}
