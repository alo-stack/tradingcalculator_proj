import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// QuickPips Design System - Premium iOS-Inspired Dark Mode
abstract class AppColors {
  // Backgrounds
  static const bg           = Color(0xFF0A0A0A); // true near-black
  static const surface      = Color(0xFF141414); // card bg
  static const surfaceHigh  = Color(0xFF1C1C1E); // input bg, inner elements
  static const surfacePill  = Color(0xFF242426); // pill/chip bg

  // Borders
  static const border       = Color(0xFF2C2C2E); // standard divider
  static const borderSubtle = Color(0xFF1F1F21); // ultra-subtle

  // Text
  static const textPrimary   = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF8E8E93);
  static const textMuted     = Color(0xFF48484A);

  // Brand
  static const accent        = Color(0xFFE8622A); // orange — use sparingly
  static const accentSurface = Color(0xFF2A1810); // orange bg tint

  // Semantic
  static const positive      = Color(0xFF30D158);
  static const positiveBg    = Color(0xFF0D2E1A);
  static const negative      = Color(0xFFFF453A);
  static const negativeBg    = Color(0xFF2E0D0D);
  
  // Aliases for backward compatibility
  static const Color background = bg;
  static const Color surfaceElevated = surfaceHigh;
  static const Color accentOrange = accent;
  static const Color accentGreen = positive;
  static const Color accentRed = negative;
  static const Color accentGreenMuted = positiveBg;
  static const Color accentRedMuted = negativeBg;
  static const Color inkwellHighlight = Color(0x14FFFFFF);
}

abstract class AppRadius {
  static const xs   = BorderRadius.all(Radius.circular(8));
  static const sm   = BorderRadius.all(Radius.circular(12));
  static const md   = BorderRadius.all(Radius.circular(16)); // standard card
  static const lg   = BorderRadius.all(Radius.circular(20)); // hero cards
  static const pill = BorderRadius.all(Radius.circular(100)); // tags, badges, buttons
}

class AppTypography {
  // Inter - for headings and large numbers
  static TextStyle display({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = -0.5,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Inter - for body and labels
  static TextStyle text({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Inter - for tab labels and badges
  static TextStyle rounded({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w500,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Section header style
  static TextStyle sectionHeader() {
    return text(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.4,
      color: AppColors.textSecondary,
    );
  }

  // Number display with tabular figures
  static TextStyle number({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentOrange,
        secondary: AppColors.textSecondary,
        surface: AppColors.surface,
        error: AppColors.accentRed,
        onPrimary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.display(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: const BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(
            color: AppColors.accentOrange,
            width: 1.5,
          ),
        ),
        labelStyle: AppTypography.text(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.text(
          fontSize: 15,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
          ),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentOrange,
          textStyle: AppTypography.text(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTypography.text(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.text(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      textTheme: TextTheme(
        displayLarge: AppTypography.display(fontSize: 57, fontWeight: FontWeight.w700),
        displayMedium: AppTypography.display(fontSize: 45, fontWeight: FontWeight.w700),
        displaySmall: AppTypography.display(fontSize: 36, fontWeight: FontWeight.w700),
        headlineLarge: AppTypography.display(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: AppTypography.display(fontSize: 28, fontWeight: FontWeight.w700),
        headlineSmall: AppTypography.display(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: AppTypography.text(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: AppTypography.text(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: AppTypography.text(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: AppTypography.text(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: AppTypography.text(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: AppTypography.text(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: AppTypography.rounded(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: AppTypography.rounded(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: AppTypography.rounded(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
  
  /// Configure system UI overlay
  static void configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
}
