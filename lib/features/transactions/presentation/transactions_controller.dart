// lib/features/transactions/presentation/transactions_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../categories/domain/category.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

/// The active list filter. All fields `null` == "Tudo" / no filter.
typedef TransactionFilter = ({
  CategoryKind? kind,
  String? categoryId,
  DateTime? from,
  DateTime? to,
});

const TransactionFilter _emptyFilter =
    (kind: null, categoryId: null, from: null, to: null);

/// The paginated list state: the accumulated [items], the [nextCursor] to fetch
/// the following page (`null` == no more), and whether a page fetch is in flight.
class TransactionsState {
  const TransactionsState({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
  });

  final List<Transaction> items;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasMore => nextCursor != null;
}

/// Owns the currently-viewed transaction list. A single notifier holding its own
/// [filter]; `setFilter`/`refresh` refetch page one, `loadMore` appends the next
/// page. Mutations are optimistic and roll back + rethrow on a [Failure].
class TransactionsController extends AsyncNotifier<TransactionsState> {
  TransactionFilter _filter = _emptyFilter;
  TransactionFilter get filter => _filter;

  TransactionsRepository get _repo => ref.read(transactionsRepositoryProvider);

  @override
  Future<TransactionsState> build() => _fetchFirstPage();

  Future<TransactionsState> _fetchFirstPage() async {
    final page = await _repo.list(
      kind: _filter.kind,
      categoryId: _filter.categoryId,
      from: _filter.from,
      to: _filter.to,
    );
    return TransactionsState(items: page.items, nextCursor: page.nextCursor);
  }

  /// Pull-to-refresh: reload page one, discarding any accumulated pages.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  /// Replace the filter wholesale (nulls clear a facet) and refetch page one.
  Future<void> setFilter(TransactionFilter filter) async {
    _filter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  /// Fetch and append the next page. No-op when already loading or at the end.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || current.nextCursor == null) {
      return;
    }
    state = AsyncData(TransactionsState(
      items: current.items,
      nextCursor: current.nextCursor,
      loadingMore: true,
    ));
    try {
      final page = await _repo.list(
        kind: _filter.kind,
        categoryId: _filter.categoryId,
        from: _filter.from,
        to: _filter.to,
        cursor: current.nextCursor,
      );
      state = AsyncData(TransactionsState(
        items: [...current.items, ...page.items],
        nextCursor: page.nextCursor,
      ));
    } on Failure {
      // Stop the spinner, keep what we had.
      state = AsyncData(TransactionsState(
        items: current.items,
        nextCursor: current.nextCursor,
      ));
      rethrow;
    }
  }

  Future<void> create({
    required int amountCents,
    required CategoryKind kind,
    required String categoryId,
    required DateTime occurredAt,
    String? description,
  }) async {
    final current = state.value ??
        const TransactionsState(items: [], nextCursor: null);
    Future<Transaction> call() => _repo.create(
          amountCents: amountCents,
          kind: kind,
          categoryId: categoryId,
          occurredAt: occurredAt,
          description: description,
        );

    final temp = Transaction(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      amountCents: amountCents,
      kind: kind,
      categoryId: categoryId,
      description: description,
      occurredAt: occurredAt,
      createdAt: DateTime.now(),
    );
    // A transaction outside the current filter doesn't belong to the visible
    // list; create it without touching state (it appears when filters clear).
    if (!_matches(temp)) {
      await call();
      return;
    }
    state = AsyncData(_withItems(current, [temp, ...current.items]));
    try {
      final created = await call();
      state = AsyncData(_withItems(current, [created, ...current.items]));
    } on Failure {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Optimistically swap the edited transaction in place. [updated] is the full
  /// post-edit entry built by the form; a null description clears it server-side.
  Future<void> edit(Transaction updated) async {
    final current = state.value ??
        const TransactionsState(items: [], nextCursor: null);
    state = AsyncData(_withItems(current, [
      for (final t in current.items) t.id == updated.id ? updated : t,
    ]));
    try {
      await _repo.update(
        updated.id,
        amountCents: updated.amountCents,
        kind: updated.kind,
        categoryId: updated.categoryId,
        occurredAt: updated.occurredAt,
        description: updated.description,
        clearDescription: updated.description == null,
      );
    } on Failure {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final current = state.value ??
        const TransactionsState(items: [], nextCursor: null);
    state = AsyncData(
        _withItems(current, [for (final t in current.items) if (t.id != id) t]));
    try {
      await _repo.delete(id);
    } on Failure {
      state = AsyncData(current);
      rethrow;
    }
  }

  TransactionsState _withItems(TransactionsState base, List<Transaction> items) =>
      TransactionsState(items: items, nextCursor: base.nextCursor);

  bool _matches(Transaction t) {
    final f = _filter;
    if (f.kind != null && t.kind != f.kind) return false;
    if (f.categoryId != null && t.categoryId != f.categoryId) return false;
    final day = DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day);
    if (f.from != null) {
      final from = DateTime(f.from!.year, f.from!.month, f.from!.day);
      if (day.isBefore(from)) return false;
    }
    if (f.to != null) {
      final to = DateTime(f.to!.year, f.to!.month, f.to!.day);
      if (day.isAfter(to)) return false;
    }
    return true;
  }
}

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, TransactionsState>(
        TransactionsController.new);
