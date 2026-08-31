import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'neo_brutalism.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.bigShoulders(
        fontSize: 57, fontWeight: FontWeight.w900, color: textColor,
      ),
      displayMedium: GoogleFonts.bigShoulders(
        fontSize: 45, fontWeight: FontWeight.w900, color: textColor,
      ),
      displaySmall: GoogleFonts.bigShoulders(
        fontSize: 36, fontWeight: FontWeight.w800, color: textColor,
      ),
      headlineLarge: GoogleFonts.bigShoulders(
        fontSize: 32, fontWeight: FontWeight.w900, color: textColor,
      ),
      headlineMedium: GoogleFonts.bigShoulders(
        fontSize: 28, fontWeight: FontWeight.w800, color: textColor,
      ),
      headlineSmall: GoogleFonts.bigShoulders(
        fontSize: 24, fontWeight: FontWeight.w800, color: textColor,
      ),
      titleLarge: GoogleFonts.archivo(
        fontSize: 22, fontWeight: FontWeight.w700, color: textColor,
      ),
      titleMedium: GoogleFonts.archivo(
        fontSize: 16, fontWeight: FontWeight.w700, color: textColor,
      ),
      titleSmall: GoogleFonts.archivo(
        fontSize: 14, fontWeight: FontWeight.w700, color: textColor,
      ),
      bodyLarge: GoogleFonts.archivo(
        fontSize: 16, fontWeight: FontWeight.w500, color: textColor,
      ),
      bodyMedium: GoogleFonts.archivo(
        fontSize: 14, fontWeight: FontWeight.w500, color: textColor,
      ),
      bodySmall: GoogleFonts.archivo(
        fontSize: 12, fontWeight: FontWeight.w400, color: textColor,
      ),
      labelLarge: GoogleFonts.dmMono(
        fontSize: 14, fontWeight: FontWeight.w500, color: textColor,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.dmMono(
        fontSize: 12, fontWeight: FontWeight.w500, color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmMono(
        fontSize: 11, fontWeight: FontWeight.w500, color: textColor,
        letterSpacing: 1.0,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.bigShoulders(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        color: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.dmMono(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
        hintStyle: GoogleFonts.archivo(
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radius),
            side: const BorderSide(
              color: AppColors.border,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          elevation: 0,
          textStyle: GoogleFonts.archivo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          ),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
          textStyle: GoogleFonts.archivo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radius),
            side: const BorderSide(
              color: AppColors.border,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          textStyle: GoogleFonts.archivo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.archivo(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.dmMono(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidthSmall,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 2,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.dmMono(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: GoogleFonts.dmMono(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            const BorderSide(
              color: AppColors.border,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.dmMono(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NeoBrutalism.radius),
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        titleTextStyle: GoogleFonts.bigShoulders(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        color: AppColors.surfaceDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radius),
            side: const BorderSide(
              color: AppColors.borderDark,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          elevation: 0,
          textStyle: GoogleFonts.archivo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          ),
          side: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
          textStyle: GoogleFonts.archivo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoBrutalism.radius),
            side: const BorderSide(
              color: AppColors.borderDark,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          textStyle: GoogleFonts.archivo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.archivo(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.dmMono(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(color: AppColors.borderDark, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 2,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.dmMono(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: GoogleFonts.dmMono(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radius),
          side: const BorderSide(
            color: AppColors.borderDark,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            const BorderSide(
              color: AppColors.borderDark,
              width: NeoBrutalism.borderWidth,
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.dmMono(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NeoBrutalism.radius),
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
      ),
    );
  }
}
