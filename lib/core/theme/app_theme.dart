import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// RedPing app theme configuration focused on safety and accessibility
class AppTheme {
  // Primary colors
  static const Color primaryRed = Color(AppConstants.primaryColorValue);
  static const Color safeGreen = Color(AppConstants.secondaryColorValue);
  static const Color warningOrange = Color(AppConstants.accentColorValue);
  static const Color darkBackground = Color(AppConstants.backgroundColorValue);
  static const Color darkSurface = Color(AppConstants.surfaceColorValue);

  // Extended color palette
  static const Color criticalRed = Color(0xFFD32F2F);
  static const Color dangerRed = Color(0xFFD32F2F); // Alias for criticalRed
  static const Color alertYellow = Color(0xFFFFC107);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color neutralGray = Color(0xFF757575);

  // Additional theme colors for gadgets
  static const Color cardBackground = darkSurface;
  static const Color borderColor = neutralGray;
  static const Color accentGreen = successGreen;
  static const Color inputBackground = darkSurface;

  // Alias properties for compatibility
  static const Color primaryColor = primaryRed;
  static const Color accentBlue = infoBlue;
  static const Color accentYellow = alertYellow;

  // Text colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color disabledText = Color(0xFF616161);

  // Get the main app theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        onPrimary: Colors.white,
        secondary: safeGreen,
        onSecondary: Colors.white,
        tertiary: warningOrange,
        onTertiary: Colors.black,
        surface: darkSurface,
        onSurface: primaryText,
        error: criticalRed,
        onError: Colors.white,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: primaryText,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: AppConstants.headingFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryRed,
        unselectedItemColor: neutralGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRed,
          side: const BorderSide(color: primaryRed, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: criticalRed, width: 2),
        ),
        labelStyle: const TextStyle(color: secondaryText),
        hintStyle: const TextStyle(color: disabledText),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryRed;
          }
          return neutralGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryRed.withValues(alpha: 0.5);
          }
          return neutralGray.withValues(alpha: 0.3);
        }),
      ),

      // Slider theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryRed,
        inactiveTrackColor: neutralGray,
        thumbColor: primaryRed,
        overlayColor: Color(0x29E53935),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryRed,
        linearTrackColor: neutralGray,
        circularTrackColor: neutralGray,
      ),

      // Snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: const TextStyle(color: primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        titleTextStyle: const TextStyle(
          color: primaryText,
          fontSize: AppConstants.subheadingFontSize,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: secondaryText,
          fontSize: AppConstants.bodyFontSize,
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primaryText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: primaryText,
          fontSize: AppConstants.headingFontSize,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: primaryText,
          fontSize: AppConstants.subheadingFontSize,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: primaryText,
          fontSize: AppConstants.bodyFontSize,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: AppConstants.bodyFontSize,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: disabledText,
          fontSize: AppConstants.captionFontSize,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: primaryText,
          fontSize: AppConstants.bodyFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: primaryText, size: 24),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: neutralGray,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Special SOS button theme
  static ButtonStyle get sosButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: primaryRed.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(AppConstants.largePadding),
      minimumSize: const Size(
        AppConstants.sosButtonSize,
        AppConstants.sosButtonSize,
      ),
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  // Emergency alert colors
  static const Map<String, Color> alertColors = {
    'critical': criticalRed,
    'warning': warningOrange,
    'info': infoBlue,
    'success': successGreen,
  };

  // Gradient definitions for special UI elements
  static const LinearGradient sosGradient = LinearGradient(
    colors: [primaryRed, criticalRed],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [safeGreen, successGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
