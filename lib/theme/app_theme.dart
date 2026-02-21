
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF121212); // Deep Black/Slate
  static const Color surface = Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color primaryBlue = Color(0xFF00F0FF); // Electric Blue
  static const Color neonRed = Color(0xFFFF003C); // Warning/Anomaly
  static const Color neonGreen = Color(0xFF39FF14); // Optimal/Safe
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFAAAAAA);

  static ThemeData get deepDarkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      canvasColor: background,
      cardColor: surface,
      
      // Text Theme
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textWhite,
        displayColor: textWhite,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: neonGreen,
        surface: surface,
        error: neonRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textWhite,
        onError: Colors.white,
      ),
    );
  }
}
