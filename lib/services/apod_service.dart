import '../models/apod.dart';
import 'api_client.dart';

/// Reads NASA's Astronomy Picture of the Day.
class ApodService {
  ApodService({required this.apiKey, required this.client});

  /// NASA API key; see `AppConfig.nasaApiKey`.
  final String apiKey;

  final ApiClient client;

  static final Uri _endpoint = Uri.parse('https://api.nasa.gov/planetary/apod');

  /// Fetches today's picture.
  Future<Apod> fetchToday() async {
    final Map<String, dynamic> json = await client.getJson(
      _endpoint.replace(queryParameters: <String, String>{'api_key': apiKey}),
    );
    return Apod.fromJson(json);
  }
}
