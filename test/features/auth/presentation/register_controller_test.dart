// test/features/auth/presentation/register_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/register_input.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/register_controller.dart';
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

const _input = RegisterInput(
    email: 'a@b.co', firstName: 'Marina', lastName: 'Costa', password: 'secret123');

ProviderContainer _container(_MockRepo repo) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    tokenStorageProvider.overrideWithValue(_FakeStorage()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() => registerFallbackValue(_input));

  test('submit success → true', () async {
    final repo = _MockRepo();
    when(() => repo.register(any())).thenAnswer((_) async {});
    final c = _container(repo);

    expect(await c.read(registerControllerProvider.notifier).submit(_input), true);
  });

  test('a conflict (email taken) → AsyncError with the API message', () async {
    final repo = _MockRepo();
    when(() => repo.register(any()))
        .thenThrow(const ConflictFailure('E-mail já cadastrado'));
    final c = _container(repo);

    final ok = await c.read(registerControllerProvider.notifier).submit(_input);
    expect(ok, false);
    expect((c.read(registerControllerProvider).error as Failure).message,
        'E-mail já cadastrado');
  });
}
