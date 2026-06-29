// lib/features/categories/presentation/widgets/delete_category_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/category.dart';
import '../categories_strings.dart';

/// Returns true when the user confirms the deletion.
Future<bool> showDeleteCategoryDialog(BuildContext context, Category category) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheet,
      title: Text(CategoriesStrings.deleteConfirmTitle, style: AppText.titleSection),
      content: Text(CategoriesStrings.deleteConfirmBody(category.name), style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(CategoriesStrings.cancel, style: AppText.bodyStrong),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(CategoriesStrings.delete,
              style: AppText.bodyStrong.copyWith(color: AppColors.expense)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
