// test/core/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/app_theme.dart';
import 'package:fluxy_app/core/theme/tokens.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('dark theme uses brand tokens', () {
    final t = buildDarkTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.primary, AppColors.primary);
    expect(t.scaffoldBackgroundColor, AppColors.bgScreen);
  });

  test('AppColors expose exact design hex values', () {
    expect(AppColors.primary, const Color(0xFF3FD68C));
    expect(AppColors.expense, const Color(0xFFF0635A));
    expect(AppColors.surface, const Color(0xFF181B21));
  });
}
