import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart'; 

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paperWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.araucariaGreen,
        primary: AppColors.volcanicObsidian,
        secondary: AppColors.araucariaGreen,
        tertiary: AppColors.copper,
        surface: AppColors.paperWhite,
        onSurface: AppColors.volcanicObsidian,
      ),

      // 2. Tipografía Editorial
      textTheme: TextTheme(
        // Display 
        displayLarge: GoogleFonts.manrope(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02 * 48,
          color: AppColors.volcanicObsidian,
        ),
        // Headlines 
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.volcanicObsidian,
        ),
        // Body 
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.6,
          color: AppColors.volcanicObsidian.withValues(alpha: 0.8),
        ),
        // Labels - Inter All Caps
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.05 * 12,
          color: AppColors.araucariaGreen,
        ),
      ),

      // 3. Botones 
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.volcanicObsidian,
          foregroundColor: AppColors.paperWhite,
          elevation: 0, 
          shape: const StadiumBorder(), 
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // 4. Inputs 
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.araucariaGreen, width: 2),
        ),
      ),
    );
  }
}