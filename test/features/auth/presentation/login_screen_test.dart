// test/features/auth/presentation/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';

// Drive the real AuthController; mock the providers it depends on.
class _MockRepo extends Mock implements AuthRepository {}

class _FakeStorage implements TokenStorage {
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<String?> readAccess() async => null;
  @override
  Future<String?> readRefresh() async => null;
  @override
  Future<void> clear() async {}
}

Widget _host(_MockRepo repo) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(_FakeStorage()),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );

void main() {
  testWidgets('renders title, fields and CTA', (tester) async {
    await tester.pumpWidget(_host(_MockRepo()));
    expect(find.text(AuthStrings.loginTitle), findsOneWidget);
    expect(find.text(AuthStrings.loginCta), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // email + password
  });

  testWidgets('invalid email shows a field error and does not call login',
      (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_host(repo));

    await tester.enterText(find.byType(TextField).at(0), 'nope');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text(AuthStrings.loginCta));
    await tester.pump();

    expect(find.text(AuthStrings.invalidEmail), findsOneWidget);
    verifyNever(() => repo.login(any(), any()));
  });

  testWidgets('a failed login shows the friendly error', (tester) async {
    final repo = _MockRepo();
    when(() => repo.login(any(), any())).thenThrow(const UnauthorizedFailure());
    await tester.pumpWidget(_host(repo));

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.text(AuthStrings.loginCta));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.invalidCredentials), findsOneWidget);
  });
}
