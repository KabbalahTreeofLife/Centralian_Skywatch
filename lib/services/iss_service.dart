import '../models/iss_position.dart';
import 'api_client.dart';

/// Reads the International Space Station's position from Where the ISS at?.
class IssService {
  IssService({required this.client});

  final ApiClient client;

  static final Uri _endpoint = Uri.parse(
    'https://api.wheretheiss.at/v1/satellites/25544',
  );

  /// Fetches the station's current position.
  Future<IssPosition> fetchPosition() async {
    final Map<String, dynamic> json = await client.getJson(_endpoint);
    return IssPosition.fromJson(json);
  }
}
