import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Renkler
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color secondaryColor = Color(0xFFFF6F00);
  static const Color lightScaffoldBackgroundColor = Color(0xFFF5F5F5);
  static const Color darkScaffoldBackgroundColor = Color(0xFF121212);

  // Ortak Button Stili
  static final ButtonStyle _buttonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(primaryColor),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50.0)),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
  );

  // Ortak Checkbox Teması
  static final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return secondaryColor; // Seçili olduğunda turuncu
      }
      return null;
    }),
    checkColor: MaterialStateProperty.all(Colors.white),
  );

  // Ortak Tooltip Teması
  static const TooltipThemeData _tooltipTheme = TooltipThemeData(
    decoration: BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    textStyle: TextStyle(color: Colors.white),
  );


  // Tema Tanımları
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightScaffoldBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    checkboxTheme: _checkboxTheme,
    tooltipTheme: _tooltipTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkScaffoldBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    checkboxTheme: _checkboxTheme,
    tooltipTheme: _tooltipTheme,
  );
}