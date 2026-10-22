import '../models/launch.dart';
import '../services/launch_service.dart';
import 'loadable_provider.dart';

/// Holds the upcoming rocket launches.
class LaunchProvider extends LoadableProvider<List<Launch>> {
  LaunchProvider({required this.service, this.limit = 10});

  final LaunchService service;

  /// How many launches to request.
  final int limit;

  @override
  Future<List<Launch>> fetch() => service.fetchUpcoming(limit: limit);
}
