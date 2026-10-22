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

  /// Whether the payload is a placeholder rather than a real picture.
  ///
  /// NASA's APOD feed sometimes answers with a partially populated record: the
  /// `explanation` is the genuine text, but `title`, `url` and `hdurl` are
  /// replaced with the site name and the site logo. Rendering that would show a
  /// logo as if it were the astronomy picture, so the entry is treated as
  /// having no usable image.
  bool get isPlaceholder =>
      _looksLikeSiteAsset(url) || _looksLikeSiteAsset(hdUrl);

  /// The best image URL for this entry, or null when there is nothing usable.
  ///
  /// Prefers the high-resolution file and falls back to the standard one.
  String? get imageUrl {
    if (!isImage || isPlaceholder) return null;
    final String candidate = hdUrl ?? url;
    return candidate.isEmpty ? null : candidate;
  }

  /// The title to show.
  ///
  /// When the feed sends the site name instead of a real title, the real title
  /// is recovered from the explanation, which reliably opens with it. The date
  /// is only a last resort, so a broken payload never shows a bare date where a
  /// title belongs.
  String get displayTitle {
    if (!isPlaceholder) return title;
    return _titleFromExplanation() ?? (date.isNotEmpty ? date : title);
  }

  /// Recovers the entry's title from the opening of [explanation].
  ///
  /// The feed writes the explanation as `<title>? <body>`, for example
  /// `Star light, star bright: is there a green star out tonight? Other than
  /// the Sun...`. The text before the first question mark is the title. Returns
  /// null when the explanation does not have that shape.
  String? _titleFromExplanation() {
    final int mark = explanation.indexOf('?');
    if (mark <= 0) return null;
    final String candidate = explanation.substring(0, mark).trim();
    // A title is a short phrase, not a paragraph. Guard against an explanation
    // that happens to contain a question mark far into the text.
    if (candidate.isEmpty || candidate.length > 120) return null;
    return candidate;
  }

  /// True when [value] points at a NASA site asset rather than an APOD image.
  ///
  /// The APOD feed serves its own theme files (for example
  /// `science.nasa.gov/wp-content/themes/.../nasa-logo@2x.png`) when it has no
  /// picture to offer. Those paths never contain a real APOD image.
  static bool _looksLikeSiteAsset(String? value) {
    if (value == null || value.isEmpty) return false;
    final String lower = value.toLowerCase();
    return lower.contains('/wp-content/themes/') ||
        lower.contains('nasa-logo') ||
        lower.contains('/assets/images/');
  }

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
