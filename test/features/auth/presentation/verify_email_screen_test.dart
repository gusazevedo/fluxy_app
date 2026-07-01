// test/features/auth/presentation/verify_email_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/core/widgets/widgets.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/verify_email_screen.dart';
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

AuthUser _user() => AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: true, createdAt: DateTime.utc(2026, 1, 1),
    );

Widget _host(_MockRepo repo) => UncontrolledProviderScope(
      container: ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(_FakeStorage()),
      ]),
      child: const MaterialApp(home: VerifyEmailScreen(email: 'a@b.co')),
    );

void main() {
  testWidgets('entering 6 digits auto-submits to repo.verifyEmail', (tester) async {
    final repo = _MockRepo();
    when(() => repo.verifyEmail(any(), any())).thenAnswer((_) async {});
    when(() => repo.me()).thenAnswer((_) async => _user());
    await tester.pumpWidget(_host(repo));
    expect(find.byType(OtpCodeInput), findsOneWidget);

    final boxes = find.byType(TextField);
    for (var i = 0; i < 6; i++) {
      await tester.enterText(boxes.at(i), '${i + 1}');
      await tester.pump();
    }
    await tester.pump();
    verify(() => repo.verifyEmail('a@b.co', '123456')).called(1);
  });

  testWidgets('resend starts a cooldown that disables the button', (tester) async {
    final repo = _MockRepo();
    when(() => repo.resendVerification(any())).thenAnswer((_) async {});
    await tester.pumpWidget(_host(repo));

    await tester.tap(find.text(AuthStrings.resendCode));
    await tester.pump();
    verify(() => repo.resendVerification('a@b.co')).called(1);
    // Now in cooldown: the active "Reenviar código" label is gone (shows a countdown).
    expect(find.text(AuthStrings.resendCode), findsNothing);
    // Let the timer cancel so the test exits cleanly.
    await tester.pump(const Duration(seconds: 61));
  });
}
