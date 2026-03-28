import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSecondary = Color(0xFF0D0D0D);
  static const Color bgCard = Color(0xFF141414);
  static const Color bgElevated = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFFF5C00);
  static const Color accentLight = Color(0xFFFF7A2F);
  static const Color accentGlow = Color(0x40FF5C00);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF555555);
  static const Color divider = Color(0xFF222222);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF1744);
  static const Color imdbColor = Color(0xFFF5C518);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgPrimary,
        primaryColor: accent,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentLight,
          background: bgPrimary,
          surface: bgCard,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            color: textPrimary,
            letterSpacing: 2,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bgSecondary,
          selectedItemColor: accent,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
        cardTheme: const CardTheme(
          color: bgCard,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.bebasNeue(
              fontSize: 48, color: textPrimary, letterSpacing: 3),
          displayMedium: GoogleFonts.bebasNeue(
              fontSize: 36, color: textPrimary, letterSpacing: 2),
          displaySmall: GoogleFonts.bebasNeue(
              fontSize: 28, color: textPrimary, letterSpacing: 2),
          headlineLarge: GoogleFonts.dmSans(
              fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
          headlineMedium: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          headlineSmall: GoogleFonts.dmSans(
              fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
          bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: textSecondary),
          bodySmall: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
          labelLarge: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: 0.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          hintStyle: GoogleFonts.dmSans(color: textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        dividerTheme:
            const DividerThemeData(color: divider, space: 1, thickness: 1),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );
}
