import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glossy White iOS Design System
/// A clean, modern, Cupertino-inspired theme with soft whites, translucent
/// layers, subtle shadows, and the Inter type scale.
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // GLOSSY WHITE / iOS COLOR PALETTE
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary – iOS blue
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryBlueLight = Color(0xFF5AC8FA);
  static const Color primaryBlueDark = Color(0xFF0056CC);

  // Accent – iOS green
  static const Color accentTeal = Color(0xFF34C759);
  static const Color accentTealLight = Color(0xFF4CD964);
  static const Color accentTealDark = Color(0xFF248A3D);

  // iOS system grays
  static const Color iosGray1 = Color(0xFF8E8E93);
  static const Color iosGray2 = Color(0xFFAEAEB2);
  static const Color iosGray3 = Color(0xFFC7C7CC);
  static const Color iosGray4 = Color(0xFFD1D1D6);
  static const Color iosGray5 = Color(0xFFE5E5EA);
  static const Color iosGray6 = Color(0xFFF2F2F7);

  // Tertiary Cyan
  static const Color accentCyan = Color(0xFF5AC8FA);
  static const Color accentCyanSoft = Color(0xFF64D2FF);

  // Surface / Background
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceOffWhite = Color(0xFFF9F9FB);
  static const Color surfaceGlass = Color(0xCCFFFFFF);
  static const Color surfaceGlassBorder = Color(0x1A000000);
  static const Color surfaceGlassDark = Color(0xE6FFFFFF);

  // Background gradients – soft white-to-lightgray
  static const Color gradientStart = Color(0xFFF9F9FB);
  static const Color gradientMiddle = Color(0xFFF2F2F7);
  static const Color gradientEnd = Color(0xFFECECF1);

  // Semantic colors – iOS standard
  static const Color successTeal = Color(0xFF34C759);
  static const Color warningAmber = Color(0xFFFF9500);
  static const Color errorCoral = Color(0xFFFF3B30);
  static const Color infoCyan = Color(0xFF5AC8FA);

  // Text colors – dark on white
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFFAEAEB2);

  // Legacy aliases for backwards compatibility
  static const Color primaryGreen = accentTeal;
  static const Color primaryEmerald = accentTeal;
  static const Color secondaryOrange = warningAmber;
  static const Color slate200 = iosGray5;
  static const Color backgroundLight = surfaceOffWhite;
  static const Color backgroundDark = Color(0xFF1C1C1E);
  static const Color cardLight = surfaceWhite;
  static const Color cardDark = surfaceGlass;
  static const Color errorRed = errorCoral;
  static const Color successGreen = successTeal;

  // Deep Ocean legacy aliases (keep for remaining references)
  static const Color primaryNavy = Color(0xFFF2F2F7);
  static const Color primaryNavyLight = Color(0xFFFFFFFF);
  static const Color primaryNavyMedium = Color(0xFFE5E5EA);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT DEFINITIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceOffWhite, iosGray6],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueLight],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF2994FF)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F8FA),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // iOS-STYLE DECORATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iosGray5.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      );

  static BoxDecoration get glassDecorationSubtle => BoxDecoration(
        color: surfaceOffWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iosGray5.withValues(alpha: 0.4),
          width: 0.5,
        ),
      );

  static BoxDecoration get accentGlassDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withValues(alpha: 0.08),
            primaryBlueLight.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryBlue.withValues(alpha: 0.15),
          width: 0.5,
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: iosGray6,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentTeal,
        tertiary: primaryBlueLight,
        surface: surfaceWhite,
        error: errorCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        surfaceContainerHighest: iosGray6,
        outline: iosGray4,
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite.withValues(alpha: 0.94),
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: primaryBlue, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: primaryBlue, width: 1),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: iosGray4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: iosGray4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorCoral, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorCoral, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: textTertiary,
          fontSize: 15,
        ),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 15,
        ),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: iosGray6,
        selectedColor: primaryBlue.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 13,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite.withValues(alpha: 0.94),
        selectedItemColor: primaryBlue,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite.withValues(alpha: 0.94),
        indicatorColor: primaryBlue.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue, size: 24);
          }
          return const IconThemeData(color: textTertiary, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xE6333333),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: iosGray5,
        thickness: 0.5,
        indent: 16,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 22,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: iosGray5,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: iosGray5,
        thumbColor: Colors.white,
        overlayColor: primaryBlue.withValues(alpha: 0.15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentTeal;
          }
          return iosGray4;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: iosGray3, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return iosGray3;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: textTertiary,
        indicatorColor: primaryBlue,
        dividerColor: iosGray5,
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
          color: const Color(0xE6333333),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: surfaceWhite,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: surfaceWhite,
        collapsedBackgroundColor: surfaceWhite,
        iconColor: textTertiary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // iOS white-first design
}
