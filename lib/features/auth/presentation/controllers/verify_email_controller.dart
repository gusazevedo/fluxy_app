// lib/features/auth/presentation/controllers/verify_email_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../data/auth_repository.dart';
import '../auth_controller.dart';
import '../auth_strings.dart';

class VerifyEmailController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> verify(String code) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).verifyEmail(code);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (_, st) {
      if (!ref.mounted) return false;
      state = AsyncError(const ValidationFailure(AuthStrings.invalidCode), st);
      return false;
    }
  }

  Future<void> resend(String email) async {
    try {
      await ref.read(authRepositoryProvider).resendVerification(email);
    } on Failure {
      // best-effort; cooldown still applies in the UI
    }
  }
}

final verifyEmailControllerProvider =
    NotifierProvider<VerifyEmailController, AsyncValue<void>>(
        VerifyEmailController.new);
