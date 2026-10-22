import 'json_utils.dart';

/// NASA's Astronomy Picture of the Day.
class Apod {
  const Apod({
    required this.title,
    required this.explanation,
    required this.url,
    required this.mediaType,
    this.hdUrl,
    this.date = '',
    this.copyright,
  });

  final String title;
  final String explanation;

  /// Image or video URL. For videos this is usually an embed URL.
  final String url;

  /// Either `image` or `video`.
  final String mediaType;

  /// High-resolution image, absent for videos and some images.
  final String? hdUrl;

  /// Calendar date as published, e.g. `2026-10-22`.
  ///
  /// Kept as a string on purpose: it is a date, not an instant, so converting
  /// it to a [DateTime] would shift it across time zones.
  final String date;

  /// Photographer or organisation. Absent when NASA owns the image.
  final String? copyright;

  /// Whether the entry can be rendered with an image widget.
  bool get isImage => mediaType == 'image';

  factory Apod.fromJson(Map<String, dynamic> json) => Apod(
    title: readString(json['title'], fallback: 'Astronomy Picture of the Day'),
    explanation: readString(json['explanation']),
    url: readString(json['url']),
    mediaType: readString(json['media_type'], fallback: 'image'),
    hdUrl: readStringOrNull(json['hdurl']),
    date: readString(json['date']),
    copyright: readStringOrNull(json['copyright']),
  );
}
