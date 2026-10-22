import '../models/launch.dart';
import 'api_client.dart';

/// Reads upcoming launches from Launch Library 2.
class LaunchService {
  LaunchService({required this.client});

  final ApiClient client;

  static final Uri _endpoint = Uri.parse(
    'https://ll.thespacedevs.com/2.2.0/launch/upcoming/',
  );

  /// Fetches the next [limit] launches.
  ///
  /// Returns an empty list when the API has no upcoming launches, so the UI can
  /// show its empty state instead of an error.
  Future<List<Launch>> fetchUpcoming({int limit = 10}) async {
    final Map<String, dynamic> json = await client.getJson(
      _endpoint.replace(
        queryParameters: <String, String>{'limit': '$limit', 'mode': 'list'},
      ),
    );

    final Object? results = json['results'];
    if (results is! List) return <Launch>[];

    return results
        .whereType<Map<String, dynamic>>()
        .map(Launch.fromJson)
        .toList(growable: false);
  }
}
