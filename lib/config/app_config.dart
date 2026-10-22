import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Values read from the environment at startup.
class AppConfig {
  AppConfig._();

  static const String _nasaKeyName = 'NASA_API_KEY';

  /// Public demo key NASA allows for light use.
  static const String demoNasaKey = 'DEMO_KEY';

  /// The NASA API key, falling back to [demoNasaKey] when `.env` is missing or
  /// does not define one.
  static String get nasaApiKey {
    try {
      final String? value = dotenv.maybeGet(_nasaKeyName);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {
      // dotenv is not loaded (for example in unit tests); use the demo key.
    }
    return demoNasaKey;
  }
}
