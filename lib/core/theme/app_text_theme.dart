import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

TextTheme buildAppTextTheme() {
  final base = GoogleFonts.vazirmatnTextTheme();
  return base.copyWith(
    headlineLarge: GoogleFonts.vazirmatn(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.carbon900),
    headlineMedium: GoogleFonts.vazirmatn(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.carbon900),
    titleMedium: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.carbon900),
    bodyLarge: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.carbon900),
    bodyMedium: GoogleFonts.vazirmatn(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.muted),
    labelLarge: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white),
  );
}
