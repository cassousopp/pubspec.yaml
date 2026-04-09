import 'package:flutter/material.dart';

class AppTheme {
  // Palette de couleurs extraite des designs Figma
  static const Color primaryBlue = Color(0xFF6366F1); // Bleu/Indigo des boutons
  static const Color secondaryPink = Color(0xFFFF4D8D); // Rose des alertes
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F2); // Fond beige très clair des cartes
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color successGreen = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);

  // Aliases pour la compatibilité avec le reste de l'application
  static const Color primary = primaryBlue;
  static const Color secondary = secondaryPink;
  static const Color darkBackground = Color(0xFF000000); // Noir pur
  static const Color darkSurface = Color(0xFF121212);    // Gris très foncé
  static const Color darkCard = Color(0xFF1E1E1E);       // Gris foncé pour les cartes
  static const Color darkText = Color(0xFFF7F6FF);

  static const LinearGradient primaryGradient = logoGradient;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat',
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: secondaryPink,
      surface: background,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textBlack),
      titleTextStyle: TextStyle(
        color: textBlack,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        fontFamily: 'Montserrat',
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: primaryBlue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textBlack),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textBlack),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBlack),
      bodyLarge: TextStyle(fontSize: 16, color: textBlack),
      bodyMedium: TextStyle(fontSize: 14, color: textGrey),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Montserrat',
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryBlue,
      secondary: secondaryPink,
      surface: darkSurface,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: darkText),
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        fontFamily: 'Montserrat',
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: primaryBlue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkText),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: darkText),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
      bodyLarge: TextStyle(fontSize: 16, color: darkText),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B0D8)),
    ),
  );

  // Dégradé pour le logo ou certains fonds
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
  );
}
