// lib/features/auth/presentation/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/reset_password_controller.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});
  final String? email;
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _codeErr, _passwordErr, _confirmErr;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {})); // live RequirementRow
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final codeErr = _code.text.trim().length == 6 ? null : AuthStrings.invalidCode;
    final passwordErr = AuthValidators.password(_password.text);
    final confirmErr = AuthValidators.confirm(_confirm.text, _password.text);
    setState(() {
      _codeErr = codeErr;
      _passwordErr = passwordErr;
      _confirmErr = confirmErr;
    });
    if (codeErr != null || passwordErr != null || confirmErr != null) return;
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit(_code.text.trim(), _password.text);
    if (ok && mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      leading: AppBackButton(onPressed: () => context.go('/login')),
      children: [
        Text(AuthStrings.resetTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.resetSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: AuthStrings.code,
          controller: _code,
          keyboardType: TextInputType.number,
          errorText: _codeErr,
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
            label: AuthStrings.newPassword, controller: _password, errorText: _passwordErr),
        const SizedBox(height: AppSpacing.sm),
        RequirementRow(
            text: AuthStrings.minChars, satisfied: _password.text.length >= 8),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
            label: AuthStrings.confirmNewPassword,
            controller: _confirm,
            errorText: _confirmErr),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: AuthStrings.savePassword, loading: loading, onPressed: loading ? null : _submit),
      ],
    );
  }
}
