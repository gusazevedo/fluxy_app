// test/core/theme/app_theme_test.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/app_theme.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  late DebugPrintCallback _savedDebugPrint;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    // google_fonts 8.x emits multiple debugPrint() calls when a font is not
    // found in app assets.  Silence those lines so the test output is pristine.
    _savedDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null &&
          (message.contains('google_fonts') ||
              message.contains('unable to load font') ||
              message.contains('troubleshooting'))) {
        return;
      }
      _savedDebugPrint(message, wrapWidth: wrapWidth);
    };
  });

  tearDownAll(() {
    debugPrint = _savedDebugPrint;
  });

  test('dark theme uses brand tokens', () {
    late ThemeData t;
    // runZonedGuarded catches the unawaited zone errors that google_fonts 8.x
    // fires asynchronously from oswaldTextTheme(); the synchronous assertions
    // below all pass before those errors settle.
    runZonedGuarded(
      () { t = buildDarkTheme(); },
      (_, __) {}, // suppress google_fonts font-load zone errors
    );
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
