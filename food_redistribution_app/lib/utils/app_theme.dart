import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deep Ocean Design System with Glassmorphism
/// A sophisticated, modern theme with navy blues, teals, and cyan accents
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP OCEAN COLOR PALETTE
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Primary Deep Navy - The foundation
  static const Color primaryNavy = Color(0xFF0A1628);
  static const Color primaryNavyLight = Color(0xFF132238);
  static const Color primaryNavyMedium = Color(0xFF1A2B4A);
  
  // Secondary Teal - Action & highlights  
  static const Color accentTeal = Color(0xFF00BFA6);
  static const Color accentTealLight = Color(0xFF26D9C2);
  static const Color accentTealDark = Color(0xFF009688);
  
  // Tertiary Cyan - Accents & gradients
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentCyanSoft = Color(0xFF4DD0E1);
  
  // Surface colors for glassmorphism
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color surfaceGlassBorder = Color(0x33FFFFFF);
  static const Color surfaceGlassDark = Color(0x0DFFFFFF);
  
  // Background gradients
  static const Color gradientStart = Color(0xFF0A1628);
  static const Color gradientMiddle = Color(0xFF0D2137);
  static const Color gradientEnd = Color(0xFF0F2847);
  
  // Semantic colors
  static const Color successTeal = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFB74D);
  static const Color errorCoral = Color(0xFFFF5252);
  static const Color infoCyan = Color(0xFF29B6F6);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textTertiary = Color(0x80FFFFFF); // 50% white
  static const Color textMuted = Color(0x4DFFFFFF); // 30% white
  
  // Legacy aliases for backwards compatibility
  static const Color primaryGreen = accentTeal;
  static const Color secondaryOrange = accentCyan;
  static const Color backgroundLight = gradientStart;
  static const Color backgroundDark = primaryNavy;
  static const Color cardLight = surfaceGlass;
  static const Color cardDark = surfaceGlassDark;
  static const Color errorRed = errorCoral;
  static const Color successGreen = successTeal;

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT DEFINITIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentTeal, accentCyan],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentTeal, accentTealLight],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASSMORPHISM DECORATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static BoxDecoration get glassDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: surfaceGlassBorder,
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration get glassDecorationSubtle => BoxDecoration(
    color: surfaceGlassDark,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: surfaceGlassBorder.withOpacity(0.5),
      width: 1,
    ),
  );
  
  static BoxDecoration get accentGlassDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentTeal.withOpacity(0.2),
        accentCyan.withOpacity(0.1),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: accentTeal.withOpacity(0.3),
      width: 1.5,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme => darkTheme; // Deep Ocean is dark-first
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: accentTeal,
        secondary: accentCyan,
        tertiary: accentTealLight,
        surface: primaryNavyLight,
        background: primaryNavy,
        error: errorCoral,
        onPrimary: primaryNavy,
        onSecondary: primaryNavy,
        onTertiary: primaryNavy,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
        surfaceVariant: primaryNavyMedium,
        outline: surfaceGlassBorder,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: primaryNavy,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          elevation: 0,
          shadowColor: accentTeal.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentTeal,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: accentTeal, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentTeal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentTeal,
        foregroundColor: primaryNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGlassDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: surfaceGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: surfaceGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorCoral, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorCoral, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 14,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: surfaceGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: surfaceGlassBorder),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceGlassDark,
        selectedColor: accentTeal.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 12,
        ),
        side: BorderSide(color: surfaceGlassBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accentTeal,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceGlassDark,
        indicatorColor: accentTeal.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: accentTeal, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: primaryNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 16,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryNavyMedium,
        contentTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: primaryNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: surfaceGlassBorder,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentTeal,
        linearTrackColor: surfaceGlassDark,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentTeal,
        inactiveTrackColor: surfaceGlassDark,
        thumbColor: accentTeal,
        overlayColor: accentTeal.withOpacity(0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentTeal;
          }
          return textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentTeal.withOpacity(0.5);
          }
          return surfaceGlassDark;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentTeal;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(primaryNavy),
        side: const BorderSide(color: textSecondary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentTeal;
          }
          return textSecondary;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentTeal,
        unselectedLabelColor: textMuted,
        indicatorColor: accentTeal,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryNavyMedium,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 12,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: surfaceGlassDark,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
