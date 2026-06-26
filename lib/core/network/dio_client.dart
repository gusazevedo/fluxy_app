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

/// Foundation wiring: real /auth/refresh is injected by the auth feature (spec 02).
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final interceptor = AuthInterceptor(
    storage,
    onRefresh: () async => false, // replaced in spec 02
    onSessionExpired: () {},       // replaced in spec 02
  );
  return buildDio(storage, interceptor);
});
