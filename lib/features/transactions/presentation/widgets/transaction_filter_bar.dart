// lib/features/transactions/presentation/widgets/transaction_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../categories/domain/category.dart';
import '../providers.dart';
import '../transactions_controller.dart';
import '../transactions_strings.dart';

/// Filter controls for the transactions list: a kind toggle
/// (Tudo/Despesa/Receita), a category dropdown, and a date-range picker. Each
/// change emits a fully-resolved [TransactionFilter] via [onChanged].
class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final TransactionFilter filter;
  final ValueChanged<TransactionFilter> onChanged;

  int get _kindIndex => switch (filter.kind) {
        null => 0,
        CategoryKind.expense => 1,
        CategoryKind.income => 2,
      };

  TransactionFilter _copyWith({
    Object? kind = _sentinel,
    Object? categoryId = _sentinel,
    Object? from = _sentinel,
    Object? to = _sentinel,
  }) =>
      (
        kind: kind == _sentinel ? filter.kind : kind as CategoryKind?,
        categoryId:
            categoryId == _sentinel ? filter.categoryId : categoryId as String?,
        from: from == _sentinel ? filter.from : from as DateTime?,
        to: to == _sentinel ? filter.to : to as DateTime?,
      );

  void _onKind(int i) => onChanged(_copyWith(
        kind: switch (i) {
          1 => CategoryKind.expense,
          2 => CategoryKind.income,
          _ => null,
        },
      ));

  Future<void> _pickPeriod(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: filter.from != null && filter.to != null
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : null,
    );
    if (range != null) {
      onChanged(_copyWith(from: range.start, to: range.end));
    }
  }

  String _periodLabel() {
    final from = filter.from, to = filter.to;
    if (from == null || to == null) return TransactionsStrings.filterPeriod;
    String d(DateTime x) =>
        '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
    return '${d(from)} – ${d(to)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPeriod = filter.from != null && filter.to != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedToggle(
          segments: const [
            TransactionsStrings.filterAll,
            TransactionsStrings.expense,
            TransactionsStrings.income,
          ],
          selectedIndex: _kindIndex,
          onChanged: _onKind,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _CategoryFilterDropdown(filter: filter, onChanged: onChanged)),
            const SizedBox(width: AppSpacing.sm),
            _PeriodButton(
              label: _periodLabel(),
              active: hasPeriod,
              onTap: () => _pickPeriod(context),
              onClear: hasPeriod
                  ? () => onChanged(_copyWith(from: null, to: null))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Sentinel so [TransactionFilterBar._copyWith] can distinguish "unchanged"
/// from an explicit null (clearing a facet).
const Object _sentinel = Object();

class _CategoryFilterDropdown extends ConsumerWidget {
  const _CategoryFilterDropdown({required this.filter, required this.onChanged});

  final TransactionFilter filter;
  final ValueChanged<TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allActiveCategoriesProvider).value ?? const [];
    final validId =
        categories.any((c) => c.id == filter.categoryId) ? filter.categoryId : null;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: validId,
          dropdownColor: AppColors.surfaceRaised,
          icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
          style: AppText.bodyStrong,
          onChanged: (id) => onChanged((
            kind: filter.kind,
            categoryId: id,
            from: filter.from,
            to: filter.to,
          )),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(TransactionsStrings.filterCategoryAll),
            ),
            for (final c in categories)
              DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_outlined,
                size: 18,
                color: active ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppText.label),
            if (onClear != null) ...[
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
