// test/features/auth/presentation/verify_email_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:mocktail/mocktail.dart';

// Drive the REAL AuthController and mock the providers it depends on.
// Mocking AuthController directly via overrideWith(() => mock) does NOT work
// with Riverpod Notifier — mount fails.
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
      id: 'u1',
      email: 'a@b.co',
      firstName: 'M',
      lastName: 'C',
      emailVerified: true,
      createdAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container(_MockRepo repo) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    tokenStorageProvider.overrideWithValue(_FakeStorage()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('verify success calls repo.verifyEmail then refreshUser (via repo.me)',
      () async {
    final repo = _MockRepo();
    when(() => repo.verifyEmail('123456')).thenAnswer((_) async {});
    when(() => repo.me()).thenAnswer((_) async => _user());
    final c = _container(repo);

    final ok =
        await c.read(verifyEmailControllerProvider.notifier).verify('123456');

    expect(ok, true);
    verify(() => repo.verifyEmail('123456')).called(1);
    verify(() => repo.me()).called(1);
  });

  test('an invalid code → AsyncError with the friendly message', () async {
    final repo = _MockRepo();
    when(() => repo.verifyEmail(any()))
        .thenThrow(const ValidationFailure('bad'));
    final c = _container(repo);

    final ok =
        await c.read(verifyEmailControllerProvider.notifier).verify('000000');

    expect(ok, false);
    expect(
      (c.read(verifyEmailControllerProvider).error as Failure).message,
      AuthStrings.invalidCode,
    );
  });

  test('resend swallows errors (best-effort)', () async {
    final repo = _MockRepo();
    when(() => repo.resendVerification(any())).thenThrow(const NetworkFailure());
    final c = _container(repo);

    await c.read(verifyEmailControllerProvider.notifier).resend('a@b.co');
    verify(() => repo.resendVerification('a@b.co')).called(1);
  });
}
