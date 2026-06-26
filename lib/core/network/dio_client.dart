// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

Dio buildDio(TokenStorage storage, AuthInterceptor interceptor) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: 'application/json',
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.add(interceptor);
  return dio;
}

/// Injection point for the auth feature (spec 02).
/// Spec 02 must override this provider (or re-wire it) to replace the two
/// stub callbacks with real implementations:
///   - `onRefresh`    → call POST /auth/refresh and persist the new tokens
///   - `onSessionExpired` → invoke logout / clear session state
/// Both stubs are intentionally no-ops so the foundation compiles without auth.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final interceptor = AuthInterceptor(
    storage,
    onRefresh: () async => false, // stub — replaced in spec 02
    onSessionExpired: () {},       // stub — replaced in spec 02
  );
  return buildDio(storage, interceptor);
});
