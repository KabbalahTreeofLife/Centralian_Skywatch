import 'package:flutter/material.dart';

import 'app_typography.dart';

/// The app's visual system: one palette, one type scale, one set of shapes.
///
/// Everything here is derived from a single seed colour, so light and dark stay
/// in step and a future palette change is a one-line edit. Screens are expected
/// to read their colours and text styles from the theme rather than hard-coding
/// them, which is what keeps the two brightnesses consistent.
class AppTheme {
  AppTheme._();

  /// Electric indigo. The tonal mapping below turns it into a deep-space
  /// palette in dark mode and a cool paper palette in light mode.
  static const Color _seed = Color(0xFF5B6CFF);

  /// Corner radius shared by cards, sheets and dialogs.
  static const double radius = 20;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = _scheme(brightness);
    final TextTheme text = AppTypography.textTheme();
    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius - 4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        strokeWidth: 3,
      ),
    );
  }

  /// The seed expanded into a full scheme, then re-toned at the surface end.
  ///
  /// `fidelity` keeps the seed's own hue instead of drifting it, which matters
  /// for an indigo that should stay indigo. The surface overrides replace the
  /// generated greys with a cooler, deeper set: near-black in dark mode so
  /// photographs carry the screen, and a soft paper tone in light mode.
  static ColorScheme _scheme(Brightness brightness) {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    if (brightness == Brightness.light) {
      return base.copyWith(
        surface: const Color(0xFFF6F7FB),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainer: const Color(0xFFF0F2F9),
        surfaceContainerHigh: const Color(0xFFE9ECF5),
        surfaceContainerHighest: const Color(0xFFE2E6F1),
        outlineVariant: const Color(0xFFDCE0EC),
      );
    }

    return base.copyWith(
      surface: const Color(0xFF0A0C12),
      surfaceContainerLowest: const Color(0xFF070910),
      surfaceContainerLow: const Color(0xFF0F121A),
      surfaceContainer: const Color(0xFF141822),
      surfaceContainerHigh: const Color(0xFF1A1F2B),
      surfaceContainerHighest: const Color(0xFF222836),
      outlineVariant: const Color(0xFF2A3142),
    );
  }
}
