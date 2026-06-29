// lib/features/auth/presentation/auth_validators.dart
import '../../../core/error/failure.dart';
import 'auth_strings.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || v.length > 320 || !_emailRe.hasMatch(v)) {
      return AuthStrings.invalidEmail;
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return AuthStrings.shortPassword;
    if (v.length > 200) return AuthStrings.longPassword;
    return null;
  }

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AuthStrings.requiredField;
    if (v.length > 100) return AuthStrings.longName;
    return null;
  }

  static String? confirm(String? value, String other) {
    if ((value ?? '') != other) return AuthStrings.passwordsDontMatch;
    return null;
  }
}

/// Maps any thrown error to a user-facing pt-BR string.
String failureText(Object? error) =>
    error is Failure ? error.message : AuthStrings.genericError;
