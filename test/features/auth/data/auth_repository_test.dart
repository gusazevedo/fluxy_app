// test/features/auth/data/auth_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_api.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_tokens.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements AuthApi {}

class _FakeStorage implements TokenStorage {
  String? access;
  String? refresh;
  int clears = 0;
  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async {
    clears++;
    access = null;
    refresh = null;
  }
}

DioException _dioErr(int code) => DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
          requestOptions: RequestOptions(path: '/auth/login'), statusCode: code),
      type: DioExceptionType.badResponse,
    );

void main() {
  late _MockApi api;
  late _FakeStorage storage;
  late AuthRepository repo;

  setUp(() {
    api = _MockApi();
    storage = _FakeStorage();
    repo = AuthRepository(api, storage);
  });

  test('login persists both tokens', () async {
    when(() => api.login('a@b.co', 'secret123')).thenAnswer((_) async =>
        const AuthTokens(accessToken: 'acc', refreshToken: 'ref'));

    await repo.login('a@b.co', 'secret123');

    expect(storage.access, 'acc');
    expect(storage.refresh, 'ref');
  });

  test('login maps a 401 DioException to a Failure', () async {
    when(() => api.login(any(), any())).thenThrow(_dioErr(401));

    expect(() => repo.login('a@b.co', 'x'), throwsA(isA<Failure>()));
  });

  test('refresh reads stored refresh, persists the rotated pair', () async {
    storage.refresh = 'r1';
    when(() => api.refresh('r1')).thenAnswer(
        (_) async => const AuthTokens(accessToken: 'a2', refreshToken: 'r2'));

    await repo.refresh();

    expect(storage.access, 'a2');
    expect(storage.refresh, 'r2');
  });

  test('refresh without a stored token throws UnauthorizedFailure', () async {
    expect(() => repo.refresh(), throwsA(isA<UnauthorizedFailure>()));
  });

  test('logout clears storage even when the API call fails', () async {
    storage.refresh = 'r1';
    when(() => api.logout(any())).thenThrow(_dioErr(500));

    await repo.logout();

    expect(storage.clears, 1);
    expect(storage.refresh, isNull);
  });

  test('verifyEmail delegates email + code to the API', () async {
    when(() => api.verifyEmail(email: 'a@b.co', code: '123456'))
        .thenAnswer((_) async {});
    await repo.verifyEmail('a@b.co', '123456');
    verify(() => api.verifyEmail(email: 'a@b.co', code: '123456')).called(1);
  });

  test('non-DioException from API is mapped to a Failure (robust _guard)', () async {
    when(() => api.me()).thenThrow(const FormatException('bad'));

    expect(() => repo.me(), throwsA(isA<Failure>()));
  });
}
