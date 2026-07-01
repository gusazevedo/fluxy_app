// lib/features/auth/data/auth_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_tokens.dart';
import '../domain/auth_user.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) =>
      _dio.post('/auth/register', data: {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
      });

  Future<void> verifyEmail({required String email, required String code}) =>
      _dio.post('/auth/verify-email', data: {'email': email, 'code': code});

  Future<void> resendVerification(String email) =>
      _dio.post('/auth/verify-email/resend', data: {'email': email});

  Future<AuthTokens> login(String email, String password) async {
    final res =
        await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final res =
        await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) =>
      _dio.post('/auth/logout', data: {'refreshToken': refreshToken});

  Future<void> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  Future<void> resetPassword(String code, String password) =>
      _dio.post('/auth/reset-password', data: {'token': code, 'password': password});

  Future<AuthUser> me() async {
    final res = await _dio.get('/me');
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));
