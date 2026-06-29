// lib/features/auth/presentation/controllers/reset_password_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../data/auth_repository.dart';
import '../auth_strings.dart';

class ResetPasswordController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(String code, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).resetPassword(code, password);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (_, st) {
      if (!ref.mounted) return false;
      state = AsyncError(const ValidationFailure(AuthStrings.invalidCode), st);
      return false;
    }
  }
}

final resetPasswordControllerProvider =
    NotifierProvider<ResetPasswordController, AsyncValue<void>>(
        ResetPasswordController.new);
