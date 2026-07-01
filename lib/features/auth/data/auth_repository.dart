// lib/features/auth/data/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';
import '../domain/register_input.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final AuthApi _api;
  final TokenStorage _storage;

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Failure {
      rethrow; // already-mapped (e.g. UnauthorizedFailure from missing token)
    } on DioException catch (e) {
      throw failureFromDio(e);
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  Future<void> register(RegisterInput input) => _guard(() => _api.register(
        email: input.email,
        firstName: input.firstName,
        lastName: input.lastName,
        password: input.password,
      ));

  Future<void> verifyEmail(String email, String code) =>
      _guard(() => _api.verifyEmail(email: email, code: code));

  Future<void> resendVerification(String email) =>
      _guard(() => _api.resendVerification(email));

  Future<void> login(String email, String password) => _guard(() async {
        final tokens = await _api.login(email, password);
        await _storage.save(
            access: tokens.accessToken, refresh: tokens.refreshToken);
      });

  Future<void> refresh() => _guard(() async {
        final current = await _storage.readRefresh();
        if (current == null) {
          throw const UnauthorizedFailure();
        }
        final tokens = await _api.refresh(current);
        await _storage.save(
            access: tokens.accessToken, refresh: tokens.refreshToken);
      });

  Future<void> forgotPassword(String email) =>
      _guard(() => _api.forgotPassword(email));

  Future<void> resetPassword(String code, String password) =>
      _guard(() => _api.resetPassword(code, password));

  Future<AuthUser> me() => _guard(() => _api.me());

  /// Best-effort server logout, then ALWAYS clear local tokens.
  Future<void> logout() async {
    final current = await _storage.readRefresh();
    if (current != null) {
      try {
        await _api.logout(current);
      } catch (_) {
        // ignore — local clear is what matters
      }
    }
    await _storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
      ref.watch(authApiProvider), ref.watch(tokenStorageProvider)),
);
