// lib/features/auth/presentation/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/session/session_status.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/register_input.dart';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Cold-start session restore runs asynchronously; paint as Unknown first.
    Future.microtask(bootstrap);
    return const AuthState.unknown();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> bootstrap() async {
    final access = await _storage.readAccess();
    final refresh = await _storage.readRefresh();
    if (!ref.mounted) return; // disposed during the async gap
    if (access == null && refresh == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    await refreshUser();
  }

  /// Loads the current user; a Failure (e.g. refresh exhausted) → signed out.
  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      if (!ref.mounted) return;
      state = AuthState.authenticated(user);
    } on Failure {
      if (!ref.mounted) return;
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
    await refreshUser();
  }

  Future<void> register(RegisterInput input) => _repo.register(input);

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  /// Invoked by the AuthInterceptor when a refresh ultimately fails.
  void onSessionExpired() {
    // Fire-and-forget local clear; flip state immediately so the router reacts.
    _storage.clear();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

SessionStatus sessionStatusFromAuth(AuthState s) => switch (s) {
      AuthUnknown() => SessionStatus.unknown,
      AuthUnauthenticated() => SessionStatus.unauthenticated,
      AuthAuthenticated(:final user) =>
        user.emailVerified ? SessionStatus.authenticated : SessionStatus.unverified,
    };
