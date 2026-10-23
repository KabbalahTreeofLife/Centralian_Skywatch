import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centralian_skywatch/theme/app_theme.dart';

/// The bottom bar spans the full width, so every tap lands on a destination and
/// paints an ink overlay across that quarter of the bar. These tests pin the
/// fix that suppresses the press overlay while leaving hover and focus
/// feedback intact.
void main() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  };

  group('navigation bar press overlay', () {
    for (final MapEntry<String, ThemeData> entry in themes.entries) {
      test('${entry.key} theme paints no overlay while pressed', () {
        final WidgetStateProperty<Color?>? overlay =
            entry.value.navigationBarTheme.overlayColor;

        expect(overlay, isNotNull);
        expect(
          overlay!.resolve(<WidgetState>{WidgetState.pressed}),
          Colors.transparent,
        );
      });

      test('${entry.key} theme keeps default hover and focus feedback', () {
        final WidgetStateProperty<Color?> overlay =
            entry.value.navigationBarTheme.overlayColor!;

        // null means "fall back to the framework default", so hover and focus
        // still respond for mouse and keyboard users.
        expect(overlay.resolve(<WidgetState>{WidgetState.hovered}), isNull);
        expect(overlay.resolve(<WidgetState>{WidgetState.focused}), isNull);
      });
    }
  });
}
