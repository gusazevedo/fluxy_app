// test/app/auth_screens_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/login_screen.dart';
import 'package:fluxy_app/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('unauthenticated boot renders the real LoginScreen at /login',
      (tester) async {
    final c = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.unauthenticated),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AuthStrings.loginTitle), findsOneWidget);

    // Navigate to register via the footer link.
    await tester.tap(find.text(AuthStrings.signUp));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
