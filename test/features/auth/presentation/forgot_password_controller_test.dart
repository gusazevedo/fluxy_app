// test/features/auth/presentation/forgot_password_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

ProviderContainer _c(_MockRepo repo) {
  final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('submit success → true and calls repo.forgotPassword', () async {
    final repo = _MockRepo();
    when(() => repo.forgotPassword('a@b.co')).thenAnswer((_) async {});
    final c = _c(repo);
    expect(await c.read(forgotPasswordControllerProvider.notifier).submit('a@b.co'), true);
    verify(() => repo.forgotPassword('a@b.co')).called(1);
  });

  test('a network error → false + AsyncError', () async {
    final repo = _MockRepo();
    when(() => repo.forgotPassword(any())).thenThrow(const NetworkFailure());
    final c = _c(repo);
    expect(await c.read(forgotPasswordControllerProvider.notifier).submit('a@b.co'), false);
    expect(c.read(forgotPasswordControllerProvider).hasError, true);
  });
}
