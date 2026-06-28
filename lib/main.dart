// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/dio_client.dart';
import 'core/session/session_status.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Real session status, derived from the auth controller.
        sessionStatusProvider.overrideWith(
            (ref) => sessionStatusFromAuth(ref.watch(authControllerProvider))),
        // Real dio whose interceptor refreshes via the repository and
        // signals the controller on terminal session expiry.
        dioProvider.overrideWith((ref) {
          final storage = ref.watch(tokenStorageProvider);
          final interceptor = AuthInterceptor(
            storage,
            onRefresh: () async {
              try {
                await ref.read(authRepositoryProvider).refresh();
                return true;
              } catch (_) {
                return false;
              }
            },
            onSessionExpired: () =>
                ref.read(authControllerProvider.notifier).onSessionExpired(),
          );
          return buildDio(storage, interceptor);
        }),
      ],
      child: const FluxyApp(),
    ),
  );
}
