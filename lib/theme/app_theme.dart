import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00D4FF),
        secondary: Color(0xFF1E88E5),
        surface: Colors.black,
        surfaceContainer: Colors.black,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: Colors.black,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        shadowColor: Colors.black26,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4FF),
          foregroundColor: Colors.black,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00D4FF),
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        hintStyle: const TextStyle(color: Color(0xFF707070)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Color(0xFFB0B0B0)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Color(0xFF00D4FF),
        unselectedItemColor: Color(0xFF707070),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFF0D0D0D)),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: Colors.black,
      ),
    );
  }
}
