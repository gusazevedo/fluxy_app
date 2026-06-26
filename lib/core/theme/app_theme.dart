// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppText {
  static TextStyle get displayAmount => GoogleFonts.fjallaOne(
      fontSize: 34, color: AppColors.primary, letterSpacing: -1);
  static TextStyle get amountMd =>
      GoogleFonts.fjallaOne(fontSize: 18, letterSpacing: -0.3);
  static TextStyle get amountSm => GoogleFonts.fjallaOne(fontSize: 15);
  static TextStyle get titleScreen => GoogleFonts.oswald(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.6);
  static TextStyle get titleSection => GoogleFonts.oswald(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.4);
  static TextStyle get titleList => GoogleFonts.oswald(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.3);
  static TextStyle get dateAnchor => GoogleFonts.oswald(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0.3);
  static TextStyle get body =>
      GoogleFonts.oswald(fontSize: 15, color: AppColors.textMuted);
  static TextStyle get bodyStrong => GoogleFonts.oswald(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary);
  static TextStyle get label =>
      GoogleFonts.oswald(fontSize: 13, color: AppColors.textMuted);
  static TextStyle get caption =>
      GoogleFonts.oswald(fontSize: 12.5, color: AppColors.textMuted);
  static TextStyle get hint =>
      GoogleFonts.oswald(fontSize: 11.5, color: AppColors.textHint);
}

ThemeData buildDarkTheme() {
  final scheme = const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.surface,
    error: AppColors.expense,
  ).copyWith(surfaceTint: Colors.transparent);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgScreen,
    textTheme: GoogleFonts.oswaldTextTheme(ThemeData.dark().textTheme)
        .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary),
  );
}
