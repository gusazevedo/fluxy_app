// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/session/session_status.dart';
import '../core/widgets/widgets.dart';
import '../core/theme/tokens.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/categories/presentation/screens/categories_screen.dart';
import 'placeholder_screens.dart';
import 'shell.dart';

const _publicRoutes = {
  '/login', '/register', '/forgot-password', '/reset-password', '/verify-email',
};

GoRouter buildRouter(Ref ref, {Listenable? refreshListenable}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final status = ref.read(sessionStatusProvider);
      final path = state.uri.path;
      final isPublic = _publicRoutes.contains(path);
      switch (status) {
        case SessionStatus.unknown:
          return path == '/splash' ? null : '/splash';
        case SessionStatus.unauthenticated:
          return isPublic ? null : '/login';
        case SessionStatus.unverified:
          return path == '/verify-email' ? null : '/verify-email';
        case SessionStatus.authenticated:
          return (isPublic || path == '/splash') ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, state) =>
              ResetPasswordScreen(email: state.uri.queryParameters['email'])),
      GoRoute(
          path: '/verify-email',
          builder: (_, state) =>
              VerifyEmailScreen(email: state.uri.queryParameters['email'] ?? '')),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const PlaceholderScreen('Início')),
          GoRoute(path: '/transactions', builder: (_, _) => const PlaceholderScreen('Transações')),
          GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
          GoRoute(path: '/account', builder: (_, _) => const PlaceholderScreen('Conta')),
        ],
      ),
    ],
  );
}

/// Bridges a Riverpod provider change into a [Listenable] for go_router.
class _ProviderRefresh extends ChangeNotifier {
  _ProviderRefresh(Ref ref) {
    ref.listen(sessionStatusProvider, (_, _) => notifyListeners());
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.bgScreen,
        body: Center(child: FluxyLogo(size: 64)),
      );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _ProviderRefresh(ref);
  ref.onDispose(refresh.dispose);
  return buildRouter(ref, refreshListenable: refresh);
});
