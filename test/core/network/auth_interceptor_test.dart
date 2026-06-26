// test/core/network/auth_interceptor_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/network/auth_interceptor.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';

class _Mem implements TokenStorage {
  String? a = 'access-1', r = 'refresh-1';
  @override Future<void> save({required String access, required String refresh}) async { a = access; r = refresh; }
  @override Future<String?> readAccess() async => a;
  @override Future<String?> readRefresh() async => r;
  @override Future<void> clear() async { a = null; r = null; }
}

void main() {
  test('onRequest attaches bearer token for non-auth routes', () async {
    final i = AuthInterceptor(_Mem(), onRefresh: () async => false, onSessionExpired: () {});
    final opts = RequestOptions(path: '/transactions');
    final handler = RequestInterceptorHandler();
    await i.onRequest(opts, handler);
    expect(opts.headers['Authorization'], 'Bearer access-1');
  });

  test('onRequest does NOT attach token for public /auth/login', () async {
    final i = AuthInterceptor(_Mem(), onRefresh: () async => false, onSessionExpired: () {});
    final opts = RequestOptions(path: '/auth/login');
    await i.onRequest(opts, RequestInterceptorHandler());
    expect(opts.headers.containsKey('Authorization'), false);
  });
}
