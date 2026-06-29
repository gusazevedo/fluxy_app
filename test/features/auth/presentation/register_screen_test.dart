// test/features/auth/presentation/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mocktail/mocktail.dart';

// Drive the real AuthController; mock the providers it depends on so the
// bootstrap microtask reads the fake storage instead of FlutterSecureStorage.
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

Widget _host() => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_MockRepo()),
        tokenStorageProvider.overrideWithValue(_FakeStorage()),
      ],
      child: const MaterialApp(home: RegisterScreen()),
    );

void main() {
  testWidgets('renders the five fields and CTA', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text(AuthStrings.registerTitle), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5)); // first, last, email, pwd, confirm
    expect(find.text(AuthStrings.registerCta), findsOneWidget);
  });

  testWidgets('mismatched passwords block submit with an inline error', (tester) async {
    await tester.pumpWidget(_host());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Marina');
    await tester.enterText(fields.at(1), 'Costa');
    await tester.enterText(fields.at(2), 'a@b.co');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'different');
    final ctaFinder = find.text(AuthStrings.registerCta);
    await tester.ensureVisible(ctaFinder);
    await tester.tap(ctaFinder);
    await tester.pump();
    expect(find.text(AuthStrings.passwordsDontMatch), findsOneWidget);
  });
}
