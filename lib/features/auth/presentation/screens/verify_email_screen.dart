// lib/features/auth/presentation/screens/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/auth_state.dart';
import '../auth_controller.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/verify_email_controller.dart';
import '../widgets/auth_scaffold.dart';

const _cooldownSeconds = 60;

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _remaining = _cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _remaining = 0);
      } else {
        if (mounted) setState(() => _remaining -= 1);
      }
    });
  }

  Future<void> _onCompleted(String code) async {
    final ok = await ref
        .read(verifyEmailControllerProvider.notifier)
        .verify(widget.email, code);
    if (!ok || !mounted) return;
    // If a session exists the router redirects to the shell automatically;
    // when there is no session (came from register), go to login.
    final authed = ref.read(authControllerProvider) is AuthAuthenticated;
    if (!authed) context.go('/login');
  }

  Future<void> _resend() async {
    _startCooldown();
    await ref.read(verifyEmailControllerProvider.notifier).resend(widget.email);
  }

  Future<void> _changeEmail() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);
    final counting = _remaining > 0;
    return AuthScaffold(
      leading: AppBackButton(onPressed: _changeEmail),
      children: [
        Text(AuthStrings.verifyTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.verifySubtitle(widget.email), style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        OtpCodeInput(onChanged: (_) {}, onCompleted: _onCompleted),
        if (state.isLoading) ...[
          const SizedBox(height: AppSpacing.lg),
          const AppLoader(),
        ],
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: counting
              ? Text(AuthStrings.resendIn(_remaining), style: AppText.label)
              : LinkButton(label: AuthStrings.resendCode, onPressed: _resend),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: LinkButton(label: AuthStrings.changeEmail, onPressed: _changeEmail),
        ),
      ],
    );
  }
}
