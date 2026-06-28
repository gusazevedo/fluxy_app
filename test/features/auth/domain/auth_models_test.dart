// test/features/auth/domain/auth_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/domain/auth_tokens.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';

void main() {
  test('AuthTokens.fromJson parses fields and defaults tokenType', () {
    final t = AuthTokens.fromJson(const {
      'accessToken': 'a',
      'refreshToken': 'r',
      'expiresIn': '3600',
    });
    expect(t.accessToken, 'a');
    expect(t.refreshToken, 'r');
    expect(t.tokenType, 'Bearer'); // default applied when absent
    expect(t.expiresIn, '3600');
  });

  test('AuthTokens.fromJson coerces a numeric expiresIn to String', () {
    final t = AuthTokens.fromJson(const {
      'accessToken': 'a',
      'refreshToken': 'r',
      'tokenType': 'Bearer',
      'expiresIn': 3600, // API may send a number
    });
    expect(t.expiresIn, '3600');
  });

  test('AuthUser.fromJson parses emailVerified and createdAt', () {
    final u = AuthUser.fromJson(const {
      'id': 'u1',
      'email': 'a@b.co',
      'firstName': 'Marina',
      'lastName': 'Costa',
      'emailVerified': false,
      'createdAt': '2026-01-02T03:04:05.000Z',
    });
    expect(u.emailVerified, false);
    expect(u.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  test('AuthState is a sealed union with three cases', () {
    final user = AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: true, createdAt: DateTime.utc(2026, 1, 1),
    );
    String label(AuthState s) => switch (s) {
          AuthUnknown() => 'unknown',
          AuthUnauthenticated() => 'unauthenticated',
          AuthAuthenticated(:final user) => 'auth:${user.email}',
        };
    expect(label(const AuthState.unknown()), 'unknown');
    expect(label(const AuthState.unauthenticated()), 'unauthenticated');
    expect(label(AuthState.authenticated(user)), 'auth:a@b.co');
  });
}
