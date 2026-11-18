import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Builds Material themes from the Tayran tokens so stock widgets (dialogs, selection, ripples)
/// also follow the design.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(Brightness.light, TayranColors.light, TayranShadows.light);

  static ThemeData dark() =>
      _build(Brightness.dark, TayranColors.dark, TayranShadows.dark);

  static ThemeData _build(
    Brightness brightness,
    TayranColors c,
    TayranShadows shadows,
  ) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      secondary: c.navy,
      onSecondary: c.onNavy,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.lineStrong,
      outlineVariant: c.line,
      scrim: c.scrim,
    );
    final text = TextTheme(
      displaySmall: TayranTypography.display,
      headlineSmall: TayranTypography.titleLg,
      titleLarge: TayranTypography.title,
      titleMedium: TayranTypography.label,
      bodyLarge: TayranTypography.bodyLg,
      bodyMedium: TayranTypography.body,
      labelLarge: TayranTypography.label,
      bodySmall: TayranTypography.caption,
      labelSmall: TayranTypography.micro,
    ).apply(bodyColor: c.ink, displayColor: c.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      fontFamily: TayranTypography.family,
      fontFamilyFallback: TayranTypography.fallback,
      textTheme: text,
      extensions: [c, shadows],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.tint,
        selectionHandleColor: c.ink,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.navy,
        contentTextStyle: TayranTypography.label.copyWith(color: c.onNavy),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TayranRadius.md)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TayranRadius.xl),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
    );
  }
}
