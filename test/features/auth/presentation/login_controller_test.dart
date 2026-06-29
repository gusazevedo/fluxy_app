// test/features/auth/presentation/login_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:mocktail/mocktail.dart';

// Mocking a Riverpod Notifier (AuthController) directly via overrideWith does not
// mount, so we drive the REAL AuthController and mock the providers it depends on.
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

ProviderContainer _container(_MockRepo repo) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    tokenStorageProvider.overrideWithValue(_FakeStorage()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('submit success → AsyncData and returns true', () async {
    final repo = _MockRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async {});
    when(() => repo.me()).thenAnswer((_) async => _user());
    final c = _container(repo);

    final ok = await c
        .read(loginControllerProvider.notifier)
        .submit('a@b.co', 'secret123');

    expect(ok, true);
    expect(c.read(loginControllerProvider).hasError, false);
  });

  test('a 401 surfaces the friendly "invalid credentials" message', () async {
    final repo = _MockRepo();
    when(() => repo.login(any(), any())).thenThrow(const UnauthorizedFailure());
    final c = _container(repo);

    final ok = await c.read(loginControllerProvider.notifier).submit('a@b.co', 'x');

    expect(ok, false);
    final state = c.read(loginControllerProvider);
    expect(state.hasError, true);
    expect((state.error as Failure).message, AuthStrings.invalidCredentials);
  });
}
