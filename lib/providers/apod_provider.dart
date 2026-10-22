import '../models/apod.dart';
import '../services/apod_service.dart';
import 'loadable_provider.dart';

/// Holds NASA's Astronomy Picture of the Day.
class ApodProvider extends LoadableProvider<Apod> {
  ApodProvider({required this.service});

  final ApodService service;

  @override
  Future<Apod> fetch() => service.fetchToday();
}
