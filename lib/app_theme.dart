import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBlueBg = Color(0xFF030A1C);
  static const Color surfaceBlue = Color(0xFF0A183D);
  static const Color lightBlueCard = Color(0xFF132A63);
  static const Color metallicGold = Color(0xFFFFD700);
  static const Color deepGold = Color(0xFFB8860B);
  static const Color correctGreen = Color(0xFF00C853);
  static const Color wrongRed = Color(0xFFD50000);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBlueBg,
      primaryColor: metallicGold,
      colorScheme: const ColorScheme.dark(
        primary: metallicGold,
        secondary: deepGold,
        surface: surfaceBlue,
      ),
      fontFamily: 'Cairo',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: metallicGold, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
