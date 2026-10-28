import 'package:flutter/material.dart';

/// Token màu & kiểu chữ theo design system "Zen Vermilion Study" (Stitch).
class Zen {
  static const canvas = Color(0xFFF7F7F4);
  static const surface = Color(0xFFFFFFFF);
  static const subtle = Color(0xFFEFECE6);
  static const border = Color(0xFFE8E5DF);

  static const primary = Color(0xFFB9343F);
  static const primaryDark = Color(0xFF9E2B35);
  static const green = Color(0xFF15803D);
  static const amber = Color(0xFFEA580C);
  static const sage = Color(0xFF3D7A5A);

  static const ink = Color(0xFF1C1917);
  static const ink2 = Color(0xFF78716C);
  static const ink3 = Color(0xFFA8A29E);

  static const radiusCard = 16.0;
  static const radiusControl = 12.0;

  static const font = 'PlusJakartaSans';
  static const jaLocale = Locale('ja', 'JP');

  /// Chữ tiếng Nhật: dùng locale ja để hệ thống chọn đúng glyph Kanji Nhật.
  static TextStyle ja(double size, {FontWeight weight = FontWeight.w500, Color color = ink, double height = 1.7}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: height, locale: jaLocale);

  static const hXL = TextStyle(fontFamily: font, fontSize: 26, fontWeight: FontWeight.w700, color: ink, height: 1.3);
  static const hLG = TextStyle(fontFamily: font, fontSize: 22, fontWeight: FontWeight.w600, color: ink, height: 1.35);
  static const hMD = TextStyle(fontFamily: font, fontSize: 18, fontWeight: FontWeight.w600, color: ink, height: 1.4);
  static const body = TextStyle(fontFamily: font, fontSize: 14, color: ink, height: 1.5);
  static const bodyLg = TextStyle(fontFamily: font, fontSize: 16, color: ink, height: 1.5);
  static const small = TextStyle(fontFamily: font, fontSize: 12, color: ink2, height: 1.5);
  static const label = TextStyle(fontFamily: font, fontSize: 13, fontWeight: FontWeight.w600, color: ink, height: 1.25);
  static const labelSm = TextStyle(fontFamily: font, fontSize: 11, fontWeight: FontWeight.w600, color: ink2, height: 1.25);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: green,
      tertiary: amber,
      surface: surface,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: hMD,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          textStyle: const TextStyle(fontFamily: font, fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          minimumSize: const Size(64, 50),
          side: const BorderSide(color: border, width: 1.5),
          textStyle: const TextStyle(fontFamily: font, fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink2,
          textStyle: const TextStyle(fontFamily: font, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected) ? primary : ink2,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? primary : ink2,
            )),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        side: const BorderSide(color: border),
        labelStyle: label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
