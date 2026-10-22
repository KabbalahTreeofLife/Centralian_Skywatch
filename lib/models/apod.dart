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
    imageUrl: readStringOrNull(json['hdurl']),
    permalink: readStringOrNull(json['permalink']),
    credit: readStringOrNull(stripHtml(json['credit'])),
    alt: readStringOrNull(stripHtml(json['alt'])),
  );
}
