// lib/core/widgets/category_icon_chip.dart
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Kind-tinted leading chip for a category row / picker entry.
/// Expense → red tint + inward arrow; income → green tint + outward arrow.
class CategoryIconChip extends StatelessWidget {
  const CategoryIconChip({super.key, required this.isExpense, this.size = 42});

  final bool isExpense;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Icon(
        isExpense ? Icons.south_west : Icons.north_east,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}
