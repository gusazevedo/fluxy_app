// lib/core/widgets/info_rows.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class HelperText extends StatelessWidget {
  const HelperText({super.key, required this.text, this.icon = Icons.schedule});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: AppText.hint)),
        ],
      );
}

class RequirementRow extends StatelessWidget {
  const RequirementRow({super.key, required this.text, required this.satisfied});
  final String text;
  final bool satisfied;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: satisfied ? AppColors.primary : Colors.transparent,
              border: satisfied ? null : Border.all(color: AppColors.textMuted),
            ),
            child: satisfied
                ? const Icon(Icons.check, size: 11, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppText.label),
        ],
      );
}
