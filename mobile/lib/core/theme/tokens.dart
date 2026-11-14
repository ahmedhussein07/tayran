// Design tokens transcribed from the design export's project/tokens.json.
// Every color, size, radius, shadow and text style in the app comes from here.
import 'package:material_ui/material_ui.dart';

/// Color tokens. Same names in both themes; values differ.
@immutable
class TayranColors extends ThemeExtension<TayranColors> {
  const TayranColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.field,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.brand,
    required this.brandPressed,
    required this.onBrand,
    required this.tint,
    required this.navyTint,
    required this.navy,
    required this.navyPressed,
    required this.onNavy,
    required this.onNavyMuted,
    required this.fresh,
    required this.freshText,
    required this.onFresh,
    required this.scrim,
    required this.danger,
    required this.onDanger,
    required this.dangerSoft,
    required this.pastelMint,
    required this.pastelWheat,
    required this.pastelSky,
    required this.pastelBlush,
    required this.pastelButter,
    required this.pastelLilac,
    required this.pastelAqua,
    required this.pastelRose,
  });

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color field;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color inkMuted;
  final Color brand;
  final Color brandPressed;
  final Color onBrand;
  final Color tint;
  final Color navyTint;
  final Color navy;
  final Color navyPressed;
  final Color onNavy;
  final Color onNavyMuted;
  final Color fresh;
  final Color freshText;
  final Color onFresh;
  final Color scrim;
  final Color danger;
  final Color onDanger;
  final Color dangerSoft;
  final Color pastelMint;
  final Color pastelWheat;
  final Color pastelSky;
  final Color pastelBlush;
  final Color pastelButter;
  final Color pastelLilac;
  final Color pastelAqua;
  final Color pastelRose;

  // Aliases defined by tokens.json.
  Color get headerBg => surfaceRaised;
  Color get link => ink;
  Color get focus => ink;

  /// Category tile pastel for a backend color token such as "pastel-mint".
  /// Unknown tokens fall back to the neutral tile (surface-sunken), as the design specifies.
  Color pastel(String token) => switch (token) {
        'pastel-mint' => pastelMint,
        'pastel-wheat' => pastelWheat,
        'pastel-sky' => pastelSky,
        'pastel-blush' => pastelBlush,
        'pastel-butter' => pastelButter,
        'pastel-lilac' => pastelLilac,
        'pastel-aqua' => pastelAqua,
        'pastel-rose' => pastelRose,
        _ => surfaceSunken,
      };

  static const light = TayranColors(
    surface: Color(0xFFFFF9F4),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFFAF5F0),
    field: Color(0xFFFFFFFF),
    line: Color(0xFFF0E6DD),
    lineStrong: Color(0xFF8F857C),
    ink: Color(0xFF1E2A3A),
    inkMuted: Color(0xFF6B7280),
    brand: Color(0xFFF77F00),
    brandPressed: Color(0xFFD96A00),
    onBrand: Color(0xFF1E2A3A),
    tint: Color(0xFFFFF0E3),
    navyTint: Color(0xFFEAF0F7),
    navy: Color(0xFF1E2A3A),
    navyPressed: Color(0xFF2E3D52),
    onNavy: Color(0xFFFFFFFF),
    onNavyMuted: Color(0xFFC3CCD8),
    fresh: Color(0xFF1F9D55),
    freshText: Color(0xFF167A42),
    onFresh: Color(0xFFFFFFFF),
    scrim: Color(0x731E2A3A),
    danger: Color(0xFFC42A1F),
    onDanger: Color(0xFFFFFFFF),
    dangerSoft: Color(0xFFFDECEA),
    pastelMint: Color(0xFFE0F8EF),
    pastelWheat: Color(0xFFF8EEE0),
    pastelSky: Color(0xFFE0ECF8),
    pastelBlush: Color(0xFFF8E0E3),
    pastelButter: Color(0xFFF8F5E0),
    pastelLilac: Color(0xFFE5E0F8),
    pastelAqua: Color(0xFFE0F3F8),
    pastelRose: Color(0xFFF8E0EF),
  );

  static const dark = TayranColors(
    surface: Color(0xFF0F151D),
    surfaceRaised: Color(0xFF18212C),
    surfaceSunken: Color(0xFF1F2935),
    field: Color(0xFF0F151D),
    line: Color(0xFF2A3644),
    lineStrong: Color(0xFF6E7A89),
    ink: Color(0xFFF3F4F6),
    inkMuted: Color(0xFFA3ABB7),
    brand: Color(0xFFF77F00),
    brandPressed: Color(0xFFFF9433),
    onBrand: Color(0xFF1E2A3A),
    tint: Color(0xFF3A2614),
    navyTint: Color(0xFF1A2B40),
    navy: Color(0xFF2C3A4E),
    navyPressed: Color(0xFF3A4A60),
    onNavy: Color(0xFFFFFFFF),
    onNavyMuted: Color(0xFFC3CCD8),
    fresh: Color(0xFF1F9D55),
    freshText: Color(0xFF4CC777),
    onFresh: Color(0xFFFFFFFF),
    scrim: Color(0xA6000000),
    danger: Color(0xFFFF7B6F),
    onDanger: Color(0xFF2A0703),
    dangerSoft: Color(0xFF3B1916),
    pastelMint: Color(0xFF163026),
    pastelWheat: Color(0xFF33291A),
    pastelSky: Color(0xFF172A3D),
    pastelBlush: Color(0xFF3A1F22),
    pastelButter: Color(0xFF33301A),
    pastelLilac: Color(0xFF28223D),
    pastelAqua: Color(0xFF15323A),
    pastelRose: Color(0xFF3A1F30),
  );

  @override
  TayranColors copyWith() => this;

  @override
  TayranColors lerp(TayranColors? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Shadow tokens (they differ per theme).
@immutable
class TayranShadows extends ThemeExtension<TayranShadows> {
  const TayranShadows({required this.card, required this.sm, required this.lg, required this.dockTop});

  final List<BoxShadow> card;
  final List<BoxShadow> sm;
  final List<BoxShadow> lg;

  /// The bottom dock's lift on the auth screens: 0 -8px 24px #1c171410.
  final List<BoxShadow> dockTop;

  static const light = TayranShadows(
    card: [
      BoxShadow(color: Color(0x0A1E2A3A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0F1E2A3A), offset: Offset(0, 4), blurRadius: 14),
    ],
    sm: [
      BoxShadow(color: Color(0x141E2A3A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x141E2A3A), offset: Offset(0, 2), blurRadius: 6),
    ],
    lg: [
      BoxShadow(color: Color(0x291E2A3A), offset: Offset(0, 10), blurRadius: 28),
      BoxShadow(color: Color(0x1A1E2A3A), offset: Offset(0, 2), blurRadius: 8),
    ],
    dockTop: [BoxShadow(color: Color(0x101C1714), offset: Offset(0, -8), blurRadius: 24)],
  );

  static const dark = TayranShadows(
    card: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2)],
    sm: [BoxShadow(color: Color(0x99000000), offset: Offset(0, 1), blurRadius: 3)],
    lg: [
      BoxShadow(color: Color(0xB3000000), offset: Offset(0, 10), blurRadius: 28),
      BoxShadow(color: Color(0xFF2A3644), spreadRadius: 1),
    ],
    dockTop: [BoxShadow(color: Color(0x40000000), offset: Offset(0, -8), blurRadius: 24)],
  );

  @override
  TayranShadows copyWith() => this;

  @override
  TayranShadows lerp(TayranShadows? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Spacing: 4px base. Screen gutter is s4; sections are s6 apart.
abstract final class TayranSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class TayranRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 9999;
}

abstract final class TayranSize {
  static const double tapMin = 44;
  static const double controlH = 48;
  static const double stepperH = 36;
  static const double tabbarH = 64;
  static const double cardW = 148;
  static const double cardWSm = 116;
}

/// The type scale. Arabic needs line height of 1.4x or more; every style keeps it.
abstract final class TayranTypography {
  static const String family = 'IBMPlexSansArabic';
  static const List<String> fallback = ['Cairo', 'Segoe UI', 'Tahoma', 'sans-serif'];

  static TextStyle _style(double size, double lineHeight, FontWeight weight) => TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static final display = _style(28, 40, FontWeight.w700);
  static final titleLg = _style(22, 32, FontWeight.w700);
  static final title = _style(18, 28, FontWeight.w700);
  static final bodyLg = _style(16, 26, FontWeight.w400);
  static final body = _style(14, 22, FontWeight.w400);
  static final label = _style(14, 20, FontWeight.w600);
  static final price = _style(16, 22, FontWeight.w700);
  static final caption = _style(12, 18, FontWeight.w500);
  static final micro = _style(11, 16, FontWeight.w600);
}

extension TayranThemeContext on BuildContext {
  TayranColors get colors => Theme.of(this).extension<TayranColors>()!;
  TayranShadows get shadows => Theme.of(this).extension<TayranShadows>()!;
}
