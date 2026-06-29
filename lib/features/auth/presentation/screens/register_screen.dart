// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/register_input.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _firstErr, _lastErr, _emailErr, _passwordErr, _confirmErr;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstErr = AuthValidators.name(_first.text);
    final lastErr = AuthValidators.name(_last.text);
    final emailErr = AuthValidators.email(_email.text);
    final passwordErr = AuthValidators.password(_password.text);
    final confirmErr = AuthValidators.confirm(_confirm.text, _password.text);
    setState(() {
      _firstErr = firstErr;
      _lastErr = lastErr;
      _emailErr = emailErr;
      _passwordErr = passwordErr;
      _confirmErr = confirmErr;
    });
    if ([firstErr, lastErr, emailErr, passwordErr, confirmErr].any((e) => e != null)) {
      return;
    }
    final email = _email.text.trim();
    final ok = await ref.read(registerControllerProvider.notifier).submit(
          RegisterInput(
            email: email,
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            password: _password.text,
          ),
        );
    if (ok && mounted) {
      context.go('/verify-email?email=${Uri.encodeComponent(email)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      leading: AppBackButton(onPressed: () => context.go('/login')),
      children: [
        Text(AuthStrings.registerTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.registerSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(label: AuthStrings.firstName, controller: _first, errorText: _firstErr),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: AuthStrings.lastName, controller: _last, errorText: _lastErr),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: AuthStrings.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailErr,
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(label: AuthStrings.password, controller: _password, errorText: _passwordErr),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
            label: AuthStrings.confirmPassword, controller: _confirm, errorText: _confirmErr),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: AuthStrings.registerCta, loading: loading, onPressed: loading ? null : _submit),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: InlineLink(
            leading: AuthStrings.haveAccount,
            action: AuthStrings.signIn,
            onPressed: () => context.go('/login'),
          ),
        ),
      ],
    );
  }
}
