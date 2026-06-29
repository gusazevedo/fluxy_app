// lib/features/auth/presentation/widgets/auth_scaffold.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, this.leading, required this.children});
  final Widget? leading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: AppSpacing.lg),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
