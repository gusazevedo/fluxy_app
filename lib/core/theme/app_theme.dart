// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

const _ui = 'Oswald';
const _amount = 'Fjalla One';

class AppText {
  static const displayAmount = TextStyle(fontFamily: _amount, fontSize: 34, color: AppColors.primary, letterSpacing: -1);
  static const amountMd = TextStyle(fontFamily: _amount, fontSize: 18, letterSpacing: -0.3);
  static const amountSm = TextStyle(fontFamily: _amount, fontSize: 15);
  static const titleScreen = TextStyle(fontFamily: _ui, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.6);
  static const titleSection = TextStyle(fontFamily: _ui, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.4);
  static const titleList = TextStyle(fontFamily: _ui, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3);
  static const dateAnchor = TextStyle(fontFamily: _ui, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3);
  static const body = TextStyle(fontFamily: _ui, fontSize: 17, color: AppColors.textMuted);
  static const bodyStrong = TextStyle(fontFamily: _ui, fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const label = TextStyle(fontFamily: _ui, fontSize: 13, color: AppColors.textMuted);
  static const caption = TextStyle(fontFamily: _ui, fontSize: 12.5, color: AppColors.textMuted);
  static const hint = TextStyle(fontFamily: _ui, fontSize: 11.5, color: AppColors.textHint);
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.surface,
    error: AppColors.expense,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme.copyWith(surfaceTint: Colors.transparent),
    scaffoldBackgroundColor: AppColors.bgScreen,
    fontFamily: _ui,
  );
}
