import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

// Package-wide test setup, auto-applied by flutter_test to every test file in
// this package (incl. the widget tests in Tasks 8 & 9) without copy-paste.
//
// We only lift the genuinely global, side-effect-free setting here:
// disabling google_fonts runtime fetching so NO test ever hits the network.
//
// The cosmetic "font not found in assets" debugPrint noise is NOT suppressed
// globally because there is no clean way to do so:
//   * Overriding the global `debugPrint` hook trips testWidgets'
//     foundation-debug-var invariant (it asserts debugPrint ==
//     debugPrintSynchronously after each widget test) -> breaks Tasks 8 & 9.
//   * A Zone `print` filter here only wraps test *registration*, not the
//     per-test zones package:test forks for execution, so it never intercepts
//     the runtime prints.
// Plain-test files that need pristine output suppress it locally (see
// test/core/theme/app_theme_test.dart). Widget tests should bundle the fonts
// as assets if pristine rendering output is required.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
