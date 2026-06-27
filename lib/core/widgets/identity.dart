// lib/core/widgets/identity.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.smBox),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
        ),
      );
}

class FluxyLogo extends StatelessWidget {
  const FluxyLogo({super.key, this.size = 52});
  final double size;

  // The logo is size-parameterized, so its geometry scales with `size`
  // rather than using a fixed AppRadii token: squircle corner ≈ 29% of the
  // tile, centered primary dot ≈ 38% (matches the design at the default 52px).
  static const _cornerRatio = 0.29;
  static const _dotRatio = 0.38;

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size * _cornerRatio),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Container(
            width: size * _dotRatio, height: size * _dotRatio,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.firstName, required this.lastName, this.size = 42});
  final String firstName;
  final String lastName;
  final double size;

  String get _initials {
    final fn = firstName.trim();
    final ln = lastName.trim();
    final f = fn.isNotEmpty ? fn[0] : '';
    final l = ln.isNotEmpty ? ln[0] : '';
    return '$f$l'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(_initials,
              style: AppText.bodyStrong.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      );
}
