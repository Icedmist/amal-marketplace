import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AmalColors {
  AmalColors._();

  static const navy = Color(0xFF0F2A5C);
  static const navyDeep = Color(0xFF0A1C3D);
  static const gold = Color(0xFFC9A44C);
  static const goldSoft = Color(0xFFE8D5A3);
  static const ink = Color(0xFF101B2D);
  static const surface = Color(0xFFF7F8FA);
  static const cream = Color(0xFFF6F0E6);
  static const muted = Color(0xFF5B6577);
  static const success = Color(0xFF0F8A4B);
  static const danger = Color(0xFFC62828);
}

class AmalTheme {
  AmalTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AmalColors.navy,
        primary: AmalColors.navy,
        secondary: AmalColors.gold,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AmalColors.surface,
    );

    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme)
        .apply(bodyColor: AmalColors.ink, displayColor: AmalColors.ink);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AmalColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AmalColors.ink,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AmalColors.navy,
        unselectedItemColor: AmalColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AmalColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AmalColors.navy,
          side: const BorderSide(color: AmalColors.navy, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AmalColors.navy,
        labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: Color(0xFFE2E6EE)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E6EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E6EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AmalColors.navy, width: 1.6),
        ),
      ),
    );
  }
}
