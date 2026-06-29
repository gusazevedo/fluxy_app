// test/features/auth/presentation/reset_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/widgets.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/reset_password_screen.dart';

void main() {
  testWidgets('renders code + two password fields and the requirement row', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())));
    // NB: resetTitle ("Nova senha") also appears as the newPassword field label,
    // so assert the unique subtitle + CTA instead of the ambiguous title text.
    expect(find.text(AuthStrings.resetSubtitle), findsOneWidget);
    expect(find.text(AuthStrings.savePassword), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3)); // code + new + confirm
    expect(find.byType(RequirementRow), findsOneWidget);
  });

  testWidgets('a short password keeps the requirement unsatisfied and blocks submit',
      (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'short'); // < 8
    await tester.enterText(fields.at(2), 'short');
    await tester.pump();
    await tester.ensureVisible(find.text(AuthStrings.savePassword));
    await tester.tap(find.text(AuthStrings.savePassword));
    await tester.pump();
    expect(find.text(AuthStrings.shortPassword), findsOneWidget);
  });
}
