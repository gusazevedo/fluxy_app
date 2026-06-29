// lib/features/auth/presentation/controllers/register_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../domain/register_input.dart';
import '../auth_controller.dart';

class RegisterController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(RegisterInput input) async {
    state = const AsyncLoading();
    try {
      await ref.read(authControllerProvider.notifier).register(input);
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

final registerControllerProvider =
    NotifierProvider<RegisterController, AsyncValue<void>>(RegisterController.new);
