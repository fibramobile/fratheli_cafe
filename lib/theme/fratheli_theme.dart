import 'package:flutter/material.dart';
import 'fratheli_colors.dart';

class FratheliTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: FratheliColors.gold,
      brightness: Brightness.light,
    ).copyWith(
      primary: FratheliColors.gold,
      surface: FratheliColors.surface,
      background: FratheliColors.bg,
      onSurface: FratheliColors.text,
      onBackground: FratheliColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: FratheliColors.bg,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: FratheliColors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: FratheliColors.text2,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: FratheliColors.text,
        ),
      ),

      // Inputs (TextField / Dropdown)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FratheliColors.surface,
        labelStyle: const TextStyle(color: FratheliColors.text2),
        hintStyle: const TextStyle(color: FratheliColors.text3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FratheliColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FratheliColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: FratheliColors.gold.withOpacity(0.75), width: 1.5),
        ),
      ),

      // Botões (Elevated)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FratheliColors.gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: FratheliColors.surfaceAlt,
        selectedColor: FratheliColors.gold.withOpacity(0.25),
        labelStyle: const TextStyle(color: FratheliColors.text),
        side: const BorderSide(color: FratheliColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
