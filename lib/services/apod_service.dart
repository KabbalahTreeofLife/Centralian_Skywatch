import 'package:flutter/foundation.dart' show debugPrint;

import '../models/apod.dart';
import '../models/json_utils.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Reads NASA's Astronomy Picture of the Day.
class ApodService {
  ApodService({required this.apiKey, required this.client});

  /// NASA API key; see `AppConfig.nasaApiKey`.
  final String apiKey;

  final ApiClient client;

  /// The live APOD feed.
  ///
  /// This is NASA's current endpoint. The older `api.nasa.gov/planetary/apod`
  /// still answers but returns a placeholder record, because `apod.nasa.gov`
  /// now redirects to `science.nasa.gov` and the legacy feed no longer finds
  /// the entry there.
  static final Uri _endpoint = Uri.parse(
    'https://science.nasa.gov/wp-json/wp/v2/apod-basic/',
  );

  /// Fetches the most recent entry.
  ///
  /// The feed returns an array of recent entries, newest first, so the first
  /// element is today's picture.
  Future<Apod> fetchToday() async {
    final List<Map<String, dynamic>> entries = await client.getJsonList(
      _endpoint.replace(queryParameters: <String, String>{'api_key': apiKey}),
    );

    if (entries.isEmpty) {
      throw const ParseException('The APOD feed returned no entries.');
    }

    final Map<String, dynamic> entry = entries.first;
    if (readString(entry['media_type']) == 'video') {
      final String? htmlUrl = readStringOrNull(entry['basic_html_url']);
      if (htmlUrl != null) {
        final Uri? uri = Uri.tryParse(htmlUrl);
        if (uri != null && uri.scheme == 'https' && _isNasaHost(uri.host)) {
          try {
            final String html = await client.getText(uri);
            final String? videoUrl = _videoUrlFromHtml(html, uri);
            if (videoUrl != null) entry['video_url'] = videoUrl;
          } on ApiException catch (error) {
            debugPrint(
              'Could not fetch the APOD video source: ${error.message}',
            );
          }
        }
      }
    }

    return Apod.fromJson(entry);
  }

  static final RegExp _videoSource = RegExp(
    r'''<source\b[^>]*\bsrc\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
    dotAll: true,
  );

  static String? _videoUrlFromHtml(String html, Uri htmlUri) {
    final String? source = _videoSource.firstMatch(html)?.group(1);
    if (source == null) return null;

    final Uri? videoUri = Uri.tryParse(source);
    if (videoUri == null) return null;
    final Uri resolved = htmlUri.resolveUri(videoUri);
    if (resolved.scheme != 'https' || !_isNasaHost(resolved.host)) return null;
    return resolved.toString();
  }

  static bool _isNasaHost(String host) =>
      host == 'nasa.gov' || host.endsWith('.nasa.gov');
}
