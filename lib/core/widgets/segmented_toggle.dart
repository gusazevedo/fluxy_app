// lib/core/widgets/segmented_toggle.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A pill-shaped segmented control. Generic over its labels so it can drive the
/// Despesa/Receita kind switch (categories, transactions) and any future binary
/// or n-ary choice.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedColor = AppColors.primary,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.chipSm),
                  ),
                  child: Text(
                    segments[i],
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong.copyWith(
                      color: i == selectedIndex
                          ? AppColors.bgScreen
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
