import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/models/apod.dart';

/// A real entry captured from
/// `science.nasa.gov/wp-json/wp/v2/apod-basic/`.
const String _sampleJson = '''
{
  "date": "2026-10-22",
  "post_id": 1497603,
  "title": "The First Green Star, WD J1330+6435",
  "permalink": "https://science.nasa.gov/image-article/apod-2026-october-22-the-first-green-star-wd-j13306435/",
  "media_type": "image",
  "explanation": "<strong>Explanation:</strong> Star light, star bright: is there a <a href=\\"https://science.nasa.gov/sun/\\">green star</a> out tonight?",
  "credit": "<a href=\\"https://markgarlick.com/\\">Mark A. Garlick</a>/<a href=\\"https://warwick.ac.uk\\">University of Warwick</a>",
  "alt": "A star shines with a greenish hue in front of a dark field.",
  "url": "https://science.nasa.gov/image-article/apod-2026-october-22-the-first-green-star-wd-j13306435/",
  "hdurl": "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/green_wd.jpg?w=1280"
}
''';

void main() {
  group('Apod.fromJson', () {
    test('parses a real APOD entry', () {
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.title, 'The First Green Star, WD J1330+6435');
      expect(apod.mediaType, 'image');
      expect(apod.date, '2026-10-22');
      expect(apod.isVideo, isFalse);
      expect(apod.hasImage, isTrue);
      expect(apod.permalink, startsWith('https://science.nasa.gov/'));
      expect(apod.alt, 'A star shines with a greenish hue in front of a dark field.');
    });

    test('takes the image from hdurl, not url', () {
      // The feed's `url` is a link to the article page. Using it as an image
      // source is what made the app show a broken picture.
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.imageUrl, startsWith('https://assets.science.nasa.gov/'));
      expect(apod.imageUrl, isNot(apod.permalink));
    });

    test('strips HTML from the explanation', () {
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.explanation, isNot(contains('<')));
      expect(apod.explanation, isNot(contains('href')));
      expect(apod.explanation, contains('Star light, star bright'));
      expect(apod.explanation, contains('green star'));
    });

    test('removes the Explanation label', () {
      // Every entry opens with <strong>Explanation:</strong>, which is a label
      // rather than prose.
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.explanation, isNot(startsWith('Explanation')));
      expect(apod.explanation, startsWith('Star light'));
    });

    test('splits the description into paragraphs on br tags', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'Two paragraphs',
        'media_type': 'image',
        'explanation':
            '<strong>Explanation:</strong> First part.<br>Second part.',
      });

      expect(apod.paragraphs, <String>['First part.', 'Second part.']);
      expect(apod.explanation, 'First part.\n\nSecond part.');
    });

    test('pulls the tomorrow teaser out of the description', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'With a teaser',
        'media_type': 'image',
        'explanation':
            '<strong>Explanation:</strong> The description.<br><br>'
            "Tomorrow's picture: eye in the sky",
      });

      expect(apod.tomorrowTeaser, "Tomorrow's picture: eye in the sky");
      expect(apod.paragraphs, <String>['The description.']);
      expect(apod.explanation, isNot(contains('Tomorrow')));
    });

    test('has no teaser when the feed sends none', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'No teaser',
        'media_type': 'image',
        'explanation': '<strong>Explanation:</strong> Just the description.',
      });

      expect(apod.tomorrowTeaser, isNull);
      expect(apod.paragraphs, <String>['Just the description.']);
    });

    test('strips HTML from the credit', () {
      final Apod apod = Apod.fromJson(
        jsonDecode(_sampleJson) as Map<String, dynamic>,
      );

      expect(apod.credit, 'Mark A. Garlick/University of Warwick');
    });

    test('decodes entities left behind by tag removal', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'Entities',
        'explanation': 'Tom &amp; Jerry &mdash; a &quot;classic&quot;.',
        'media_type': 'image',
      });

      expect(apod.explanation, 'Tom & Jerry — a "classic".');
    });

    test('a video entry still carries a still frame', () {
      // The feed gives video entries a poster image in hdurl, so the picture
      // is shown and the button opens the page to play it.
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'Sonified: Eagle Nebula Pillars',
        'media_type': 'video',
        'url': 'https://science.nasa.gov/image-article/apod-2026-october-18/',
        'hdurl': 'https://assets.science.nasa.gov/dynamicimage/x.jpg',
      });

      expect(apod.isVideo, isTrue);
      expect(apod.hasImage, isTrue);
      expect(apod.imageUrl, 'https://assets.science.nasa.gov/dynamicimage/x.jpg');
    });

    test('an entry with no hdurl has no image', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'No picture',
        'media_type': 'image',
        'url': 'https://science.nasa.gov/image-article/x/',
      });

      expect(apod.hasImage, isFalse);
      expect(apod.imageUrl, isNull);
    });

    test('an empty hdurl is treated as missing', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'Empty picture',
        'media_type': 'image',
        'hdurl': '',
      });

      expect(apod.imageUrl, isNull);
    });

    test('survives an empty object', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{});

      expect(apod.title, 'Astronomy Picture of the Day');
      expect(apod.mediaType, 'image');
      expect(apod.explanation, '');
      expect(apod.date, '');
      expect(apod.imageUrl, isNull);
      expect(apod.credit, isNull);
      expect(apod.permalink, isNull);
    });

    test('keeps the date as a string so it cannot shift time zones', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'date': '2026-10-22',
        'title': 'A date',
        'media_type': 'image',
      });

      expect(apod.date, '2026-10-22');
    });
  });

  group('sizedImageUrl', () {
    test('scales a large picture down to the requested edge', () {
      // The feed asks for the original upload size, which for some entries is
      // several megabytes, for a picture shown 240px tall.
      final String? url = sizedImageUrl(
        'https://assets.science.nasa.gov/x.jpg?w=7200&h=5361&fit=clip',
      );

      expect(url, contains('w=1080'));
      expect(url, contains('h=804'));
    });

    test('preserves the aspect ratio', () {
      final String? url = sizedImageUrl(
        'https://assets.science.nasa.gov/x.jpg?w=2622&h=1751',
      );

      final Uri parsed = Uri.parse(url!);
      final int w = int.parse(parsed.queryParameters['w']!);
      final int h = int.parse(parsed.queryParameters['h']!);

      // 2622/1751 is about 1.497, and the scaled pair must match it.
      expect(w / h, closeTo(2622 / 1751, 0.01));
      expect(w, 1080);
    });

    test('keeps the other parameters', () {
      final String? url = sizedImageUrl(
        'https://assets.science.nasa.gov/x.jpg?w=5120&h=3840&fit=clip&crop=faces',
      );

      expect(url, contains('fit=clip'));
      expect(url, contains('crop=faces'));
    });

    test('leaves a picture that is already small enough alone', () {
      const String original = 'https://assets.science.nasa.gov/x.jpg?w=800&h=600';

      expect(sizedImageUrl(original), original);
    });

    test('leaves a url with no query string alone', () {
      const String original = 'https://example.test/a.jpg';

      expect(sizedImageUrl(original), original);
    });

    test('leaves a url with no dimensions alone', () {
      const String original = 'https://example.test/a.jpg?fit=clip';

      expect(sizedImageUrl(original), original);
    });

    test('leaves a url with unparseable dimensions alone', () {
      const String original = 'https://example.test/a.jpg?w=big&h=small';

      expect(sizedImageUrl(original), original);
    });

    test('returns null for a missing url', () {
      expect(sizedImageUrl(null), isNull);
      expect(sizedImageUrl(''), isNull);
    });

    test('is applied when parsing an entry', () {
      final Apod apod = Apod.fromJson(<String, dynamic>{
        'title': 'A picture',
        'media_type': 'image',
        'hdurl': 'https://assets.science.nasa.gov/x.jpg?w=5120&h=3840',
      });

      expect(apod.imageUrl, contains('w=1080'));
    });
  });
}
