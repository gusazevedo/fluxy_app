// lib/features/auth/presentation/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _backToLogin() =>
      context.canPop() ? context.pop() : context.go('/login');

  Future<void> _submit() async {
    final emailError = AuthValidators.email(_email.text);
    setState(() => _emailError = emailError);
    if (emailError != null) return;
    final email = _email.text.trim();
    final ok = await ref.read(forgotPasswordControllerProvider.notifier).submit(email);
    if (ok && mounted) {
      context.go('/reset-password?email=${Uri.encodeComponent(email)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      leading: AppBackButton(onPressed: _backToLogin),
      children: [
        Text(AuthStrings.forgotTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.forgotSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: AuthStrings.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: AuthStrings.sendCode, loading: loading, onPressed: loading ? null : _submit),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: InlineLink(
            leading: AuthStrings.rememberedPassword,
            action: AuthStrings.backToLogin,
            onPressed: _backToLogin,
          ),
        ),
      ],
    );
  }
}
