// test/features/auth/presentation/reset_password_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

ProviderContainer _c(_MockRepo repo) {
  final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('submit posts code+password and returns true', () async {
    final repo = _MockRepo();
    when(() => repo.resetPassword('123456', 'newpass12')).thenAnswer((_) async {});
    final c = _c(repo);
    expect(await c.read(resetPasswordControllerProvider.notifier).submit('123456', 'newpass12'),
        true);
    verify(() => repo.resetPassword('123456', 'newpass12')).called(1);
  });

  test('a bad code → false + friendly message', () async {
    final repo = _MockRepo();
    when(() => repo.resetPassword(any(), any())).thenThrow(const ValidationFailure('bad'));
    final c = _c(repo);
    expect(await c.read(resetPasswordControllerProvider.notifier).submit('000000', 'newpass12'),
        false);
    expect((c.read(resetPasswordControllerProvider).error as Failure).message,
        AuthStrings.invalidCode);
  });
}
