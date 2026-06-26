// test/core/network/auth_interceptor_test.dart
import 'dart:async';

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

/// Records which terminal method onError invoked, without completing the real
/// internal completer (nothing awaits it in a unit test).
class _FakeErrorHandler extends ErrorInterceptorHandler {
  int nextCount = 0;
  int resolveCount = 0;
  DioException? lastError;
  @override
  void next(DioException error) {
    nextCount++;
    lastError = error;
  }
  @override
  void resolve(Response response) {
    resolveCount++;
  }
}

DioException _err401(String path) {
  final opts = RequestOptions(path: path);
  return DioException(
    requestOptions: opts,
    response: Response(requestOptions: opts, statusCode: 401),
  );
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

  test('onError single-flight: concurrent 401s refresh exactly once', () async {
    var refreshCount = 0;
    final gate = Completer<void>();
    final i = AuthInterceptor(
      _Mem(),
      onRefresh: () async {
        refreshCount++;
        await gate.future;
        return false;
      },
      onSessionExpired: () {},
    );
    // Fire two concurrent 401s; both reach the single-flight gate before it opens.
    final f1 = i.onError(_err401('/transactions'), _FakeErrorHandler());
    final f2 = i.onError(_err401('/transactions'), _FakeErrorHandler());
    gate.complete();
    await Future.wait([f1, f2]);
    expect(refreshCount, 1);
  });

  test('onError refresh false: onSessionExpired once and error propagated', () async {
    var expired = 0;
    final i = AuthInterceptor(
      _Mem(),
      onRefresh: () async => false,
      onSessionExpired: () => expired++,
    );
    final handler = _FakeErrorHandler();
    final err = _err401('/transactions');
    await i.onError(err, handler);
    expect(expired, 1);
    expect(handler.nextCount, 1);
    expect(handler.resolveCount, 0);
    expect(handler.lastError, same(err));
  });

  test('onError refresh throws: treated as failure, no hang, error propagated', () async {
    var expired = 0;
    final i = AuthInterceptor(
      _Mem(),
      onRefresh: () async => throw Exception('refresh boom'),
      onSessionExpired: () => expired++,
    );
    final handler = _FakeErrorHandler();
    final err = _err401('/transactions');
    // Completing at all proves no hang; assertions prove failure handling.
    await i.onError(err, handler);
    expect(expired, 1);
    expect(handler.nextCount, 1);
    expect(handler.resolveCount, 0);
    expect(handler.lastError, same(err));
  });
}
