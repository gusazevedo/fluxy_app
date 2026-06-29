// test/features/auth/presentation/forgot_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/forgot_password_screen.dart';

void main() {
  testWidgets('renders title, email field and CTA', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())));
    expect(find.text(AuthStrings.forgotTitle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(AuthStrings.sendCode), findsOneWidget);
  });

  testWidgets('an invalid email blocks submit', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())));
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text(AuthStrings.sendCode));
    await tester.pump();
    expect(find.text(AuthStrings.invalidEmail), findsOneWidget);
  });
}
