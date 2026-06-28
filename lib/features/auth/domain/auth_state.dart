// lib/features/auth/domain/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_user.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.authenticated(AuthUser user) = AuthAuthenticated;
}
