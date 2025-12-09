import 'package:flutter/material.dart';

/// Paleta principal de la aplicacion.
class AppColors {
  static const Color primary50 = Color(0xFFE5E5FF);
  static const Color primary100 = Color(0xFFCCCCFF);
  static const Color primary200 = Color(0xFF9999FF);
  static const Color primary300 = Color(0xFF6666FF);
  static const Color primary400 = Color(0xFF3333FF);
  static const Color primary500 = Color(0xFF0000FF);
  static const Color primary600 = Color(0xFF0000CC);
  static const Color primary700 = Color(0xFF000099);
  static const Color primary800 = Color(0xFF000066);
  static const Color primary900 = Color(0xFF000033);

  static const MaterialColor primarySwatch = MaterialColor(
    0xFF0000FF,
    <int, Color>{
      50: primary50,
      100: primary100,
      200: primary200,
      300: primary300,
      400: primary400,
      500: primary500,
      600: primary600,
      700: primary700,
      800: primary800,
      900: primary900,
    },
  );
}

/// Tema unico de la app usando la paleta definida.
class ThemeProvider {
  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary500,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary500,
      secondary: AppColors.primary300,
      primaryContainer: AppColors.primary100,
      secondaryContainer: AppColors.primary200,
      surface: Colors.white,
      background: AppColors.primary50,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: AppColors.primary500,
      primarySwatch: AppColors.primarySwatch,
      scaffoldBackgroundColor: AppColors.primary50,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primary50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.primary300),
        labelStyle: TextStyle(color: AppColors.primary700),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.primary100,
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary700,
        unselectedLabelColor: AppColors.primary300,
        indicatorColor: AppColors.primary500,
      ),
    );
  }
}
