// test/core/theme/app_theme_test.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/app_theme.dart';
import 'package:fluxy_app/core/theme/tokens.dart';

// google_fonts runtime-fetch is disabled package-wide by
// test/flutter_test_config.dart. The debugPrint noise it emits for fonts that
// aren't bundled as assets is suppressed locally below: this is a plain
// test() file (no testWidgets invariant check), so overriding debugPrint here
// is safe and properly restored in tearDownAll.

void main() {
  late DebugPrintCallback savedDebugPrint;

  setUpAll(() {
    // Plain test() does not auto-init the binding; oswaldTextTheme() touches
    // the asset bundle, which requires an initialized binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    savedDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null &&
          (message.contains('google_fonts') ||
              message.contains('unable to load font') ||
              message.contains("troubleshooting doesn't solve the problem"))) {
        return;
      }
      savedDebugPrint(message, wrapWidth: wrapWidth);
    };
  });

  tearDownAll(() {
    debugPrint = savedDebugPrint;
  });

  test('dark theme uses brand tokens', () {
    late ThemeData t;
    // runZonedGuarded catches the unawaited zone error google_fonts 8.x fires
    // asynchronously from oswaldTextTheme() (font not in app assets). Only that
    // known noise is swallowed; any other zone error fails the test.
    runZonedGuarded(
      () { t = buildDarkTheme(); },
      (e, _) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('google_fonts') ||
            msg.contains('googlefonts') ||
            msg.contains('allowruntimefetching') ||
            msg.contains('unable to load font') ||
            msg.contains('not found in the application assets')) {
          return;
        }
        fail('Unexpected zone error: $e');
      },
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
