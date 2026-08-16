import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lime500,
      brightness: Brightness.light,
      primary: AppColors.lime500, // Lime is now primary
      onPrimary: AppColors.carbon900,
      secondary: AppColors.carbon900, // Carbon as secondary
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.carbon900,
    ),
    textTheme: buildAppTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lime500,
      foregroundColor: AppColors.carbon900,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 70,
      iconTheme: const IconThemeData(color: AppColors.carbon900, size: 24), // التأكد من لون وحجم زرار الرجوع
      titleTextStyle: GoogleFonts.vazirmatn(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.carbon900,
        letterSpacing: -0.8,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lime500,
        foregroundColor: AppColors.carbon900,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.carbon900,
        side: const BorderSide(color: AppColors.carbon900, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.6),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lime300,
      labelStyle: GoogleFonts.vazirmatn(color: AppColors.carbon900, fontWeight: FontWeight.w700, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.carbon900, width: 1.6),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.carbon900,
      unselectedItemColor: AppColors.muted,
      selectedLabelStyle: GoogleFonts.vazirmatn(fontSize: 11, fontWeight: FontWeight.w700),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.lime500,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.vazirmatn(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.carbon900);
        }
        return GoogleFonts.vazirmatn(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted);
      }),
    ),
  );
}
