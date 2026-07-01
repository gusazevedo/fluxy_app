// lib/features/transactions/presentation/widgets/delete_transaction_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../transactions_strings.dart';

/// Returns true when the user confirms the deletion.
Future<bool> showDeleteTransactionDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheet,
      title: Text(TransactionsStrings.deleteConfirmTitle,
          style: AppText.titleSection),
      content:
          Text(TransactionsStrings.deleteConfirmBody, style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(TransactionsStrings.cancel, style: AppText.bodyStrong),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(TransactionsStrings.delete,
              style: AppText.bodyStrong.copyWith(color: AppColors.expense)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
