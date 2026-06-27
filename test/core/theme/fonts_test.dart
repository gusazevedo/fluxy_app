// test/core/theme/fonts_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/app_theme.dart';

void main() {
  test('AppText uses bundled Oswald/Fjalla families, not google_fonts', () {
    expect(AppText.titleScreen.fontFamily, 'Oswald');
    expect(AppText.bodyStrong.fontFamily, 'Oswald');
    expect(AppText.displayAmount.fontFamily, 'Fjalla One');
    expect(AppText.amountSm.fontFamily, 'Fjalla One');
    // weights preserved
    expect(AppText.titleScreen.fontWeight, FontWeight.w700);
    expect(AppText.bodyStrong.fontWeight, FontWeight.w500);
  });
}
