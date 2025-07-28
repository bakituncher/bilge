// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana Renkler
  static const Color primaryColor = Color(0xFF1B263B); // Koyu Lacivert
  static const Color secondaryColor = Color(0xFFFCA311); // Canlı Turuncu
  static const Color accentColor = Color(0xFFE53935); // Kırmızı - Hata/Uyarı
  static const Color successColor = Color(0xFF43A047); // Yeşil - Başarı

  // Arka Plan Renkleri
  static const Color lightScaffoldBackgroundColor = Color(0xFFF4F7FC);
  static const Color darkScaffoldBackgroundColor = Color(0xFF0D1B2A);

  // Kart Renkleri
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color darkCardColor = Color(0xFF1B263B);

  // Metin Renkleri
  static const Color lightTextColor = Color(0xFF1B263B);
  static const Color darkTextColor = Color(0xFFE0E1DD);

  // Merkezi Buton Stili
  static final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: primaryColor,
    minimumSize: const Size(double.infinity, 52.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    elevation: 4.0,
    textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
  );

  // Merkezi TextField Stili
  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide.none,
    ),
    filled: true,
  );

  // Tema oluşturan ana fonksiyon
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color textColor,
    required Color cardColor,
    required Color inputFillColor,
  }) {
    final baseTheme = ThemeData(brightness: brightness);
    return baseTheme.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: primaryColor,
        error: accentColor,
        onError: Colors.white,
        surface: cardColor,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
      inputDecorationTheme: _inputDecorationTheme.copyWith(
        fillColor: inputFillColor,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: secondaryColor,
        unselectedItemColor: textColor.withAlpha(153), // ~0.6 opacity
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  // Açık Tema
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightScaffoldBackgroundColor,
    textColor: lightTextColor,
    cardColor: lightCardColor,
    inputFillColor: const Color(0xFFEDF2F7),
  );

  // Koyu Tema
  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkScaffoldBackgroundColor,
    textColor: darkTextColor,
    cardColor: darkCardColor,
    inputFillColor: const Color(0xFF2D3748),
  );
}