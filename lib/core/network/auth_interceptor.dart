// lib/core/network/auth_interceptor.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

bool _isPublicAuthRoute(String path) {
  // /auth/* are public EXCEPT change-password.
  // Prefix match so a path like /x/auth/y is not misclassified.
  if (!path.startsWith('/auth/')) return false;
  return !path.startsWith('/auth/change-password');
}

class AuthInterceptor extends Interceptor {
  // Named initializing formals: callers use `onRefresh`/`onSessionExpired`
  // (the leading underscore is stripped by Dart); the fields stay private.
  AuthInterceptor(
    this._storage, {
    required this._onRefresh,
    required this._onSessionExpired,
  });

  final TokenStorage _storage;
  final Future<bool> Function() _onRefresh;
  final void Function() _onSessionExpired;

  // Single-flight: concurrent 401s await one refresh.
  Future<bool>? _refreshing;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublicAuthRoute(options.path)) {
      final token = await _storage.readAccess();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isAuthRoute = _isPublicAuthRoute(err.requestOptions.path);
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;

    if (!is401 || isAuthRoute || alreadyRetried) {
      return handler.next(err);
    }

    // Guard a throwing refresh (offline / 500 on the refresh endpoint): a throw
    // must be treated as refresh-failure, never escape onError and hang the
    // original request. whenComplete still resets _refreshing across the throw.
    bool ok;
    try {
      ok = await (_refreshing ??= _onRefresh().whenComplete(() {
        _refreshing = null;
      }));
    } catch (_) {
      ok = false;
    }

    if (!ok) {
      _onSessionExpired();
      return handler.next(err);
    }

    // Retry the original request once with the new token.
    final token = await _storage.readAccess();
    final opts = err.requestOptions
      ..extra['__retried'] = true
      ..headers['Authorization'] = 'Bearer $token';
    // Use a throwaway Dio so the retry does not re-enter this interceptor.
    final dio = Dio(BaseOptions(baseUrl: opts.baseUrl));
    try {
      final res = await dio.fetch(opts);
      return handler.resolve(res);
    } on DioException catch (e) {
      return handler.next(e);
    } finally {
      dio.close();
    }
  }
}
