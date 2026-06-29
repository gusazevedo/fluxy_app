// lib/features/categories/presentation/widgets/category_row.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/category.dart';
import '../categories_strings.dart';

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.onRename,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: category.archived ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gap),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            CategoryIconChip(isExpense: category.kind == CategoryKind.expense),
            const SizedBox(width: AppSpacing.gap),
            Expanded(
              child: Text(category.name,
                  style: AppText.bodyStrong, overflow: TextOverflow.ellipsis),
            ),
            if (category.archived)
              const _ArchivedTag()
            else
              PopupMenuButton<String>(
                color: AppColors.surfaceRaised,
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'rename',
                      child: Text(CategoriesStrings.rename, style: AppText.bodyStrong)),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(CategoriesStrings.delete,
                          style: AppText.bodyStrong.copyWith(color: AppColors.expense))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedTag extends StatelessWidget {
  const _ArchivedTag();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.chipSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(CategoriesStrings.archivedTag, style: AppText.caption),
      );
}
