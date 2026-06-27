import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Text(label,
            style: AppText.body.copyWith(
                color: AppColors.primary, fontSize: 13.5, fontWeight: FontWeight.w500)),
      );
}

class InlineLink extends StatelessWidget {
  const InlineLink({super.key, required this.leading, required this.action, required this.onPressed});
  final String leading;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$leading ', style: AppText.body),
          GestureDetector(
            onTap: onPressed,
            behavior: HitTestBehavior.opaque,
            child: Text(action, style: AppText.bodyStrong),
          ),
        ],
      );
}
