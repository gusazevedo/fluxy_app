// test/features/auth/presentation/auth_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/domain/register_input.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _FakeStorage implements TokenStorage {
  String? access;
  String? refresh;
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

AuthUser _user({bool verified = true}) => AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: verified, createdAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container(_MockRepo repo, _FakeStorage storage) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    tokenStorageProvider.overrideWithValue(storage),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('no stored token → unauthenticated', () async {
    final repo = _MockRepo();
    final c = _container(repo, _FakeStorage());

    expect(c.read(authControllerProvider), const AuthState.unknown());
    await c.read(authControllerProvider.notifier).bootstrap();
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('stored token + me() success → authenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);

    await c.read(authControllerProvider.notifier).bootstrap();
    expect(c.read(authControllerProvider), AuthState.authenticated(_user()));
  });

  test('stored token + me() Failure → unauthenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenThrow(const UnauthorizedFailure());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);

    await c.read(authControllerProvider.notifier).bootstrap();
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('login then refreshUser → authenticated', () async {
    final repo = _MockRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async {});
    when(() => repo.me()).thenAnswer((_) async => _user());
    final c = _container(repo, _FakeStorage());

    await c.read(authControllerProvider.notifier).login('a@b.co', 'secret123');
    expect(c.read(authControllerProvider), AuthState.authenticated(_user()));
  });

  test('onSessionExpired → unauthenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);
    await c.read(authControllerProvider.notifier).bootstrap();

    c.read(authControllerProvider.notifier).onSessionExpired();
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('build() auto-runs bootstrap (no explicit call) → authenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);

    // Read once to construct the notifier; do NOT call bootstrap() ourselves.
    expect(c.read(authControllerProvider), const AuthState.unknown());
    await pumpEventQueue(); // let build()'s Future.microtask(bootstrap) settle
    expect(c.read(authControllerProvider), AuthState.authenticated(_user()));
    verify(() => repo.me()).called(1);
  });

  test('logout calls the repo and transitions to unauthenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    when(() => repo.logout()).thenAnswer((_) async {});
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);
    c.read(authControllerProvider); // first read → build() schedules auto-bootstrap
    await pumpEventQueue(); // drain auto-bootstrap → authenticated
    expect(c.read(authControllerProvider), AuthState.authenticated(_user()));

    await c.read(authControllerProvider.notifier).logout();

    verify(() => repo.logout()).called(1);
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('onSessionExpired clears stored tokens', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final storage = _FakeStorage()
      ..access = 'acc'
      ..refresh = 'ref';
    final c = _container(repo, storage);
    c.read(authControllerProvider); // first read → build() schedules auto-bootstrap
    await pumpEventQueue(); // drain auto-bootstrap before mutating state

    c.read(authControllerProvider.notifier).onSessionExpired();
    await pumpEventQueue(); // clear() is fire-and-forget

    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('register delegates to the repository', () async {
    final repo = _MockRepo();
    const input = RegisterInput(
        email: 'a@b.co', firstName: 'M', lastName: 'C', password: 'secret123');
    when(() => repo.register(input)).thenAnswer((_) async {});
    final c = _container(repo, _FakeStorage());

    await c.read(authControllerProvider.notifier).register(input);

    verify(() => repo.register(input)).called(1);
  });

  test('sessionStatusFromAuth maps the three cases (incl. unverified)', () {
    expect(sessionStatusFromAuth(const AuthState.unknown()),
        SessionStatus.unknown);
    expect(sessionStatusFromAuth(const AuthState.unauthenticated()),
        SessionStatus.unauthenticated);
    expect(sessionStatusFromAuth(AuthState.authenticated(_user(verified: true))),
        SessionStatus.authenticated);
    expect(sessionStatusFromAuth(AuthState.authenticated(_user(verified: false))),
        SessionStatus.unverified);
  });
}
