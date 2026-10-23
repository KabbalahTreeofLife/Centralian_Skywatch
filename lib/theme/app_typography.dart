import 'package:flutter/material.dart';

/// The app's type system.
///
/// Two bundled variable fonts carry the whole scale: Space Grotesk for display
/// and headings, Inter for everything read as prose or UI. Both are declared
/// once in `pubspec.yaml`, so every weight comes from a single asset and the
/// app never fetches a font at runtime.
class AppTypography {
  AppTypography._();

  /// Used for screen titles, countdowns and the big readout values.
  static const String display = 'SpaceGrotesk';

  /// Used for body copy, labels and buttons.
  static const String body = 'Inter';

  /// Builds a style with its weight applied to the variable font's `wght` axis.
  ///
  /// A static family resolves `fontWeight` on its own, but a variable font
  /// needs the axis set explicitly. Both are written and kept in agreement so
  /// the style is correct whether the engine reads the axis or the weight.
  static TextStyle _style(
    String family,
    double size,
    int weight, {
    double? height,
    double? tracking,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      letterSpacing: tracking,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
    );
  }

  /// The full Material 3 scale, mapped onto the two families.
  ///
  /// Display and headline sizes are tightened (`letterSpacing` below zero)
  /// because Space Grotesk is wide at large sizes; body copy is loosened with a
  /// generous line height so long APOD descriptions stay readable.
  static TextTheme textTheme() {
    return TextTheme(
      displayLarge: _style(display, 52, 600, height: 1.05, tracking: -1.4),
      displayMedium: _style(display, 44, 600, height: 1.08, tracking: -1.2),
      displaySmall: _style(display, 36, 600, height: 1.1, tracking: -0.8),
      headlineLarge: _style(display, 32, 600, height: 1.15, tracking: -0.6),
      headlineMedium: _style(display, 28, 600, height: 1.18, tracking: -0.4),
      headlineSmall: _style(display, 24, 600, height: 1.2, tracking: -0.3),
      titleLarge: _style(display, 20, 600, height: 1.25, tracking: -0.2),
      titleMedium: _style(body, 16, 600, height: 1.35),
      titleSmall: _style(body, 14, 600, height: 1.35),
      bodyLarge: _style(body, 16, 400, height: 1.55),
      bodyMedium: _style(body, 14, 400, height: 1.55),
      bodySmall: _style(body, 12, 400, height: 1.45),
      labelLarge: _style(body, 14, 600, height: 1.2, tracking: 0.1),
      labelMedium: _style(body, 12, 500, height: 1.2, tracking: 0.2),
      labelSmall: _style(body, 11, 500, height: 1.2, tracking: 0.4),
    );
  }
}
