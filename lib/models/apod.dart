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
    this.date = '',
    this.imageUrl,
    this.permalink,
    this.credit,
    this.alt,
  });

  /// The entry's real title, e.g. `The First Green Star, WD J1330+6435`.
  final String title;

  /// The description, with HTML removed.
  final String explanation;

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

  factory Apod.fromJson(Map<String, dynamic> json) => Apod(
    title: readString(json['title'], fallback: 'Astronomy Picture of the Day'),
    explanation: stripHtml(json['explanation']),
    mediaType: readString(json['media_type'], fallback: 'image'),
    date: readString(json['date']),
    imageUrl: sizedImageUrl(readStringOrNull(json['hdurl'])),
    permalink: readStringOrNull(json['permalink']),
    credit: readStringOrNull(stripHtml(json['credit'])),
    alt: readStringOrNull(stripHtml(json['alt'])),
  );
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
  final Map<String, String> params = Map<String, String>.of(uri.queryParameters);
  params['w'] = '${(width * scale).round()}';
  params['h'] = '${(height * scale).round()}';

  return uri.replace(queryParameters: params).toString();
}
