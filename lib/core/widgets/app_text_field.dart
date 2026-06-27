// lib/core/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label, style: AppText.label),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: hasError ? AppColors.expense : AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: AppText.bodyStrong,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: AppText.body,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errorText!, style: AppText.caption.copyWith(color: AppColors.expense)),
          ),
      ],
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.label, this.controller, this.errorText});
  final String label;
  final TextEditingController? controller;
  final String? errorText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => AppTextField(
        label: widget.label,
        controller: widget.controller,
        errorText: widget.errorText,
        obscure: _obscure,
        trailing: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20, color: AppColors.textMuted),
        ),
      );
}
