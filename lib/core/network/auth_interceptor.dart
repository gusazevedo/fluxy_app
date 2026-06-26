// lib/core/network/auth_interceptor.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

bool _isPublicAuthRoute(String path) {
  // /auth/* are public EXCEPT change-password.
  if (!path.contains('/auth/')) return false;
  return !path.contains('/auth/change-password');
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage, {
    required Future<bool> Function() onRefresh,
    required void Function() onSessionExpired,
  })  : _onRefresh = onRefresh,
        _onSessionExpired = onSessionExpired;

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

    final ok = await (_refreshing ??= _onRefresh().whenComplete(() {
      _refreshing = null;
    }));

    if (!ok) {
      _onSessionExpired();
      return handler.next(err);
    }

    // Retry the original request once with the new token.
    final token = await _storage.readAccess();
    final opts = err.requestOptions
      ..extra['__retried'] = true
      ..headers['Authorization'] = 'Bearer $token';
    try {
      // Use a throwaway Dio so the retry does not re-enter this interceptor.
      final dio = Dio(BaseOptions(baseUrl: opts.baseUrl));
      final res = await dio.fetch(opts);
      return handler.resolve(res);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
