// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/session/session_status.dart';
import 'placeholder_screens.dart';
import 'shell.dart';

const _publicRoutes = {
  '/login', '/register', '/forgot-password', '/reset-password', '/verify-email',
};

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final status = ref.read(sessionStatusProvider);
      final path = state.uri.path;
      final isPublic = _publicRoutes.contains(path);
      switch (status) {
        case SessionStatus.unknown:
          return null;
        case SessionStatus.unauthenticated:
          return isPublic ? null : '/login';
        case SessionStatus.unverified:
          return path == '/verify-email' ? null : '/verify-email';
        case SessionStatus.authenticated:
          return isPublic ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPlaceholder()),
      GoRoute(path: '/register', builder: (_, _) => Scaffold(body: PlaceholderScreen('Cadastro'))),
      GoRoute(path: '/forgot-password', builder: (_, _) => Scaffold(body: PlaceholderScreen('Recuperar senha'))),
      GoRoute(path: '/reset-password', builder: (_, _) => Scaffold(body: PlaceholderScreen('Nova senha'))),
      GoRoute(path: '/verify-email', builder: (_, _) => Scaffold(body: PlaceholderScreen('Verificar e-mail'))),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const PlaceholderScreen('Início')),
          GoRoute(path: '/transactions', builder: (_, _) => const PlaceholderScreen('Transações')),
          GoRoute(path: '/categories', builder: (_, _) => const PlaceholderScreen('Categorias')),
          GoRoute(path: '/account', builder: (_, _) => const PlaceholderScreen('Conta')),
        ],
      ),
    ],
  );
}

/// SPEC 02 WIRING NOTE: spec 02 must also add a router `refreshListenable` so
/// that passive session-status changes (e.g. `onSessionExpired` firing) cause
/// go_router to re-run `redirect` and bounce the user to /login.
/// Without it, `redirect` only fires on explicit navigation events.
/// Example: `ref.listen(sessionStatusProvider, (_, _) => router.refresh())`
/// wired via a `ProviderObserver` or inside the provider itself.
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
