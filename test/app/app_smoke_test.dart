// test/app/app_smoke_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/app.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('FluxyApp boots into the login screen (unauthenticated)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FluxyApp()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AuthStrings.loginTitle), findsOneWidget);
  });
}
