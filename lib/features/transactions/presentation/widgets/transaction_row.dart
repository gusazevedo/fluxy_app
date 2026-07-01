// lib/features/transactions/presentation/widgets/transaction_row.dart
import 'package:flutter/material.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction.dart';
import '../transactions_strings.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    required this.categoryName,
    this.onTap,
  });

  final Transaction transaction;
  final String categoryName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.kind == CategoryKind.expense;
    final description = transaction.description;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gap),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            CategoryIconChip(isExpense: isExpense),
            const SizedBox(width: AppSpacing.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName.isEmpty
                        ? TransactionsStrings.noCategory
                        : categoryName,
                    style: AppText.bodyStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(description,
                        style: AppText.caption, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              Money(transaction.amountCents).formatSigned(isExpense),
              style: AppText.amountSm.copyWith(
                color: isExpense ? AppColors.expense : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
