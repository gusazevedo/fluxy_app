// lib/features/auth/presentation/controllers/login_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../auth_controller.dart';
import '../auth_strings.dart';

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authControllerProvider.notifier).login(email, password);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (e, st) {
      if (!ref.mounted) return false;
      // A 401 on login means bad credentials, not an expired session.
      final shown = e is UnauthorizedFailure
          ? const ValidationFailure(AuthStrings.invalidCredentials)
          : e;
      state = AsyncError(shown, st);
      return false;
    }
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(LoginController.new);
