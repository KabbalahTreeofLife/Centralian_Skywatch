import '../models/apod.dart';
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

    return Apod.fromJson(entries.first);
  }
}
