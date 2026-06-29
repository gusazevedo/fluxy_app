// lib/features/auth/presentation/controllers/forgot_password_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (e, st) {
      if (!ref.mounted) return false;
      state = AsyncError(e, st);
      return false;
    }
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, AsyncValue<void>>(
        ForgotPasswordController.new);
