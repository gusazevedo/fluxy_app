// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = AuthValidators.email(_email.text);
    final passwordError = AuthValidators.password(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) return;
    // Success flips AuthState → the router redirects automatically.
    await ref
        .read(loginControllerProvider.notifier)
        .submit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      children: [
        const FluxyLogo(),
        const SizedBox(height: AppSpacing.lg),
        Text(AuthStrings.loginTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.loginSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: AuthStrings.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
          label: AuthStrings.password,
          controller: _password,
          errorText: _passwordError,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: LinkButton(
            label: AuthStrings.forgotPassword,
            onPressed: () => context.push('/forgot-password'),
          ),
        ),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: AuthStrings.loginCta,
          loading: loading,
          haptic: true,
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: InlineLink(
            leading: AuthStrings.noAccount,
            action: AuthStrings.signUp,
            onPressed: () => context.push('/register'),
          ),
        ),
      ],
    );
  }
}
