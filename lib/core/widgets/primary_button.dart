// lib/core/widgets/primary_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pressable_shadow_button.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      child: PressableShadowButton(
        onPressed: enabled ? onPressed : null,
        child: loading
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary))
            : Text(label, textAlign: TextAlign.center,
                style: AppText.bodyStrong.copyWith(color: AppColors.onPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
