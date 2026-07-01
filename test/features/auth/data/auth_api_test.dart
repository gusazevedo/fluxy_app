// test/features/auth/data/auth_api_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/data/auth_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(String path, dynamic data, [int code = 200]) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: code,
      data: data,
    );

void main() {
  late _MockDio dio;
  late AuthApi api;

  setUp(() {
    dio = _MockDio();
    api = AuthApi(dio);
  });

  test('login posts credentials and parses tokens', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
      (_) async => _resp('/auth/login', {
        'accessToken': 'acc',
        'refreshToken': 'ref',
        'tokenType': 'Bearer',
        'expiresIn': '3600',
      }),
    );

    final tokens = await api.login('a@b.co', 'secret123');

    expect(tokens.accessToken, 'acc');
    expect(tokens.refreshToken, 'ref');
    verify(() => dio.post('/auth/login',
        data: {'email': 'a@b.co', 'password': 'secret123'})).called(1);
  });

  test('verifyEmail posts email + code', () async {
    when(() => dio.post('/auth/verify-email', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/auth/verify-email', {'message': 'ok'}));

    await api.verifyEmail(email: 'a@b.co', code: '123456');

    verify(() => dio.post('/auth/verify-email',
        data: {'email': 'a@b.co', 'code': '123456'})).called(1);
  });

  test('resetPassword posts token + password', () async {
    when(() => dio.post('/auth/reset-password', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/auth/reset-password', {'message': 'ok'}));

    await api.resetPassword('123456', 'newpass12');

    verify(() => dio.post('/auth/reset-password',
        data: {'token': '123456', 'password': 'newpass12'})).called(1);
  });

  test('refresh posts the refresh token and parses rotated tokens', () async {
    when(() => dio.post('/auth/refresh', data: any(named: 'data'))).thenAnswer(
      (_) async => _resp('/auth/refresh',
          {'accessToken': 'a2', 'refreshToken': 'r2', 'tokenType': 'Bearer'}),
    );

    final tokens = await api.refresh('r1');

    expect(tokens.accessToken, 'a2');
    expect(tokens.refreshToken, 'r2');
    verify(() => dio.post('/auth/refresh', data: {'refreshToken': 'r1'}))
        .called(1);
  });

  test('me() GETs /me and parses the user', () async {
    when(() => dio.get('/me')).thenAnswer((_) async => _resp('/me', {
          'id': 'u1',
          'email': 'a@b.co',
          'firstName': 'Marina',
          'lastName': 'Costa',
          'emailVerified': true,
          'createdAt': '2026-01-02T03:04:05.000Z',
        }));

    final user = await api.me();

    expect(user.id, 'u1');
    expect(user.emailVerified, true);
    verify(() => dio.get('/me')).called(1);
  });
}
