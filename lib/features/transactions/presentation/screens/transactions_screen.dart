// lib/features/transactions/presentation/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/time/display_date.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/transaction.dart';
import '../providers.dart';
import '../transactions_controller.dart';
import '../transactions_strings.dart';
import '../widgets/transaction_form_sheet.dart';
import '../widgets/transaction_row.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) _loadMore();
  }

  void _edit(Transaction tx) => showFluxySheet(
        context,
        title: TransactionsStrings.editTitle,
        child: TransactionFormSheet(existing: tx),
      );

  Future<void> _loadMore() async {
    try {
      await ref.read(transactionsControllerProvider.notifier).loadMore();
    } on Failure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TransactionsStrings.loadMoreError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);
    final names = ref.watch(categoryNamesProvider).value ?? const {};
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(TransactionsStrings.tab, style: AppText.titleScreen),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: state.when(
                loading: () => const AppLoader(),
                error: (e, _) => AppErrorView(
                  message: e is Failure ? e.message : TransactionsStrings.loadError,
                  onRetry: () =>
                      ref.invalidate(transactionsControllerProvider),
                ),
                data: (data) => data.items.isEmpty
                    ? _EmptyRefreshable(
                        onRefresh: () => ref
                            .read(transactionsControllerProvider.notifier)
                            .refresh(),
                      )
                    : _TransactionsList(
                        controller: _scroll,
                        entries: _buildEntries(data.items),
                        names: names,
                        loadingMore: data.loadingMore,
                        onTap: _edit,
                        onRefresh: () => ref
                            .read(transactionsControllerProvider.notifier)
                            .refresh(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flattens the (occurredAt-desc) list into interleaved day headers + rows.
List<Object> _buildEntries(List<Transaction> items) {
  final out = <Object>[];
  DateTime? lastDay;
  for (final t in items) {
    final day = DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day);
    if (lastDay == null || day != lastDay) {
      out.add(_DayHeader(day));
      lastDay = day;
    }
    out.add(t);
  }
  return out;
}

class _DayHeader {
  const _DayHeader(this.day);
  final DateTime day;
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.controller,
    required this.entries,
    required this.names,
    required this.loadingMore,
    required this.onTap,
    required this.onRefresh,
  });

  final ScrollController controller;
  final List<Object> entries;
  final Map<String, String> names;
  final bool loadingMore;
  final ValueChanged<Transaction> onTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: entries.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= entries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppLoader(),
            );
          }
          final entry = entries[i];
          if (entry is _DayHeader) {
            return Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(dayLabel(entry.day), style: AppText.dateAnchor),
            );
          }
          final tx = entry as Transaction;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TransactionRow(
              transaction: tx,
              categoryName: names[tx.categoryId] ?? '',
              onTap: () => onTap(tx),
            ),
          );
        },
      ),
    );
  }
}

/// Keeps pull-to-refresh available even when the list is empty.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            AppEmptyView(message: TransactionsStrings.empty),
          ],
        ),
      );
}
