import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF3F51B5);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Each destination fills a quarter of the bar, so the whole bar is a
        // tap target and every tap paints an ink overlay across that quarter.
        // The indicator pill already shows which tab is selected, so the press
        // overlay is redundant noise. Hover and focus keep their default
        // feedback so mouse and keyboard users still get a response.
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.pressed) ? Colors.transparent : null,
        ),
      ),
    );
  }
}
