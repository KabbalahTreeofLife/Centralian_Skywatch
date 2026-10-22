import '../models/iss_position.dart';
import '../services/iss_service.dart';
import 'loadable_provider.dart';

/// Holds the International Space Station's latest reported position.
class IssProvider extends LoadableProvider<IssPosition> {
  IssProvider({required this.service});

  final IssService service;

  @override
  Future<IssPosition> fetch() => service.fetchPosition();
}
