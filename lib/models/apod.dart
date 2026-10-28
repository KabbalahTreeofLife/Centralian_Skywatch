import 'json_utils.dart';

/// NASA's Astronomy Picture of the Day.
///
/// Parsed from `science.nasa.gov/wp-json/wp/v2/apod-basic/`, which returns an
/// array of recent entries, newest first.
class Apod {
  const Apod({
    required this.title,
    required this.explanation,
    required this.mediaType,
    this.paragraphs = const <String>[],
    this.tomorrowTeaser,
    this.date = '',
    this.imageUrl,
    this.videoUrl,
    this.permalink,
    this.credit,
    this.alt,
  });

  /// The entry's real title, e.g. `The First Green Star, WD J1330+6435`.
  final String title;

  /// The description, with HTML removed and the `Explanation:` label stripped.
  final String explanation;

  /// The description split into paragraphs.
  ///
  /// The feed marks its breaks with `<br>` tags, so this keeps the author's
  /// structure instead of collapsing it into one block.
  final List<String> paragraphs;

  /// The feed's trailing `Tomorrow's picture: ...` teaser, when it sends one.
  ///
  /// It is a note about the next entry rather than part of this one, so it is
  /// kept out of [paragraphs] and shown separately.
  final String? tomorrowTeaser;

  /// Either `image` or `video`.
  final String mediaType;

  /// Calendar date as published, e.g. `2026-10-22`.
  ///
  /// Kept as a string on purpose: it is a date, not an instant, so converting
  /// it to a [DateTime] would shift it across time zones.
  final String date;

  /// The picture itself, or null when the feed sends none.
  ///
  /// The feed's `url` field is a link to the article page, not an image, so the
  /// image always comes from `hdurl`. Video entries still carry a still frame
  /// here, which is what the list and detail views show.
  final String? imageUrl;

  /// Direct playable media URL for supported video entries.
  final String? videoUrl;

  /// Link to the entry's page on science.nasa.gov.
  final String? permalink;

  /// Photographer or organisation, with HTML removed.
  final String? credit;

  /// Description of the image for screen readers.
  final String? alt;

  /// Whether the entry is a video rather than a still picture.
  bool get isVideo => mediaType == 'video';

  /// Whether there is a picture to render.
  bool get hasImage => imageUrl != null;

  factory Apod.fromJson(Map<String, dynamic> json) {
    final Object? storedParagraphs = json['paragraphs'];
    final List<String> parts = storedParagraphs is List
        ? storedParagraphs
              .whereType<String>()
              .map(stripExplanationLabel)
              .where((String part) => part.isNotEmpty)
              .toList(growable: false)
        : splitHtmlParagraphs(json['explanation'])
              .map(stripExplanationLabel)
              .where((String part) => part.isNotEmpty)
              .toList(growable: false);

    // The feed ends the explanation with a note about the next entry. It is not
    // part of this one, so it is pulled out and shown on its own.
    final String? teaser =
        readStringOrNull(json['tomorrow_teaser']) ?? _teaserFrom(parts);
    final bool hasInlineTeaser =
        teaser != null &&
        parts.isNotEmpty &&
        parts.last.toLowerCase().startsWith("tomorrow's picture");
    final List<String> paragraphs = hasInlineTeaser
        ? parts.sublist(0, parts.length - 1)
        : parts;

    return Apod(
      title: readString(
        json['title'],
        fallback: 'Astronomy Picture of the Day',
      ),
      explanation: paragraphs.join('\n\n'),
      paragraphs: paragraphs,
      tomorrowTeaser: teaser,
      mediaType: readString(json['media_type'], fallback: 'image'),
      date: readString(json['date']),
      imageUrl: sizedImageUrl(readStringOrNull(json['hdurl'])),
      videoUrl: readStringOrNull(json['video_url']),
      permalink: readStringOrNull(json['permalink']),
      credit: readStringOrNull(stripHtml(json['credit'])),
      alt: readStringOrNull(stripHtml(json['alt'])),
    );
  }

  /// JSON snapshot used to restore this entry from the favorites list.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'explanation': explanation,
    'paragraphs': paragraphs,
    'tomorrow_teaser': tomorrowTeaser,
    'media_type': mediaType,
    'date': date,
    'hdurl': imageUrl,
    'video_url': videoUrl,
    'permalink': permalink,
    'credit': credit,
    'alt': alt,
  };

  /// Returns the trailing `Tomorrow's picture:` note, or null when absent.
  static String? _teaserFrom(List<String> parts) {
    if (parts.isEmpty) return null;

    final String last = parts.last;
    final bool isTeaser = last.toLowerCase().startsWith("tomorrow's picture");
    return isTeaser ? last : null;
  }
}

/// The longest edge to request from NASA's image service.
///
/// The picture is shown in a 240px-tall frame that spans the screen width, so
/// 1080px covers a 360pt-wide phone at 3x without fetching more than the screen
/// can show.
const int _requestedImageEdge = 1080;

/// Rewrites the feed's image URL to ask for a smaller picture.
///
/// The feed asks for the picture at its original upload size, which for some
/// entries is several megabytes: the 2026-10-21 entry is 2622x1751 and weighs
/// 8.6 MB, for a picture shown 240px tall.
///
/// NASA's image service takes `w` and `h` parameters, and returns a picture
/// whose longest edge is the smaller of the two. Both are scaled by the same
/// factor so the shape is preserved; changing only one would crop or distort
/// the picture.
///
/// Returns the URL unchanged when it has no query string, no `w` parameter, or
/// no usable dimensions, so an entry from a different host still loads rather
/// than breaking.
String? sizedImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.queryParameters.isEmpty) return url;

  final int? width = int.tryParse(uri.queryParameters['w'] ?? '');
  final int? height = int.tryParse(uri.queryParameters['h'] ?? '');
  if (width == null || height == null || width <= 0 || height <= 0) return url;

  // Already small enough: leave it alone rather than upscaling.
  final int longestEdge = width > height ? width : height;
  if (longestEdge <= _requestedImageEdge) return url;

  final double scale = _requestedImageEdge / longestEdge;
  final Map<String, String> params = Map<String, String>.of(
    uri.queryParameters,
  );
  params['w'] = '${(width * scale).round()}';
  params['h'] = '${(height * scale).round()}';

  return uri.replace(queryParameters: params).toString();
}
