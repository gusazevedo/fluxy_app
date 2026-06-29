// test/features/auth/presentation/auth_validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/presentation/auth_validators.dart';

void main() {
  group('email', () {
    test('rejects empty and malformed', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('nope'), isNotNull);
      expect(AuthValidators.email('a@b'), isNotNull);
    });
    test('accepts a well-formed address', () {
      expect(AuthValidators.email('a@b.co'), isNull);
    });
  });

  group('password', () {
    test('rejects < 8 chars', () => expect(AuthValidators.password('1234567'), isNotNull));
    test('accepts 8..200', () {
      expect(AuthValidators.password('12345678'), isNull);
      expect(AuthValidators.password('a' * 200), isNull);
    });
    test('rejects > 200', () => expect(AuthValidators.password('a' * 201), isNotNull));
  });

  group('name', () {
    test('rejects empty/whitespace', () {
      expect(AuthValidators.name(''), isNotNull);
      expect(AuthValidators.name('   '), isNotNull);
    });
    test('accepts a trimmed name and rejects > 100', () {
      expect(AuthValidators.name('Marina'), isNull);
      expect(AuthValidators.name('a' * 101), isNotNull);
    });
  });

  group('confirm', () {
    test('rejects a mismatch, accepts a match', () {
      expect(AuthValidators.confirm('abcd1234', 'other'), isNotNull);
      expect(AuthValidators.confirm('abcd1234', 'abcd1234'), isNull);
    });
  });

  group('failureText', () {
    test('uses Failure.message', () {
      expect(failureText(const NetworkFailure()), const NetworkFailure().message);
    });
    test('falls back for a non-Failure', () {
      expect(failureText(Exception('x')), isNotEmpty);
    });
  });
}
