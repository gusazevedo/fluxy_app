import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/data/transactions_repository.dart';
import 'package:fluxy_app/features/transactions/domain/transaction.dart';
import 'package:fluxy_app/features/transactions/domain/transactions_page.dart';
import 'package:fluxy_app/features/transactions/presentation/transactions_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionsRepository {}

Transaction _tx(
  String id, {
  CategoryKind kind = CategoryKind.expense,
  String categoryId = 'c1',
}) =>
    Transaction(
      id: id,
      amountCents: 1234,
      kind: kind,
      categoryId: categoryId,
      description: null,
      occurredAt: DateTime(2026, 6, 30),
      createdAt: DateTime.utc(2026, 6, 30, 12),
    );

TransactionsPage _page(List<Transaction> items, String? cursor) =>
    TransactionsPage(items: items, nextCursor: cursor);

ProviderContainer _container(_MockRepo repo) {
  final c = ProviderContainer(
    overrides: [transactionsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

/// The unfiltered first-page fetch the controller issues on build/refresh.
void _stubFirstPage(_MockRepo repo, TransactionsPage page) {
  when(() => repo.list(kind: null, categoryId: null, from: null, to: null))
      .thenAnswer((_) async => page);
}

void main() {
  test('build loads the first page with its cursor', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], 'eyJ'));
    final c = _container(repo);

    final state = await c.read(transactionsControllerProvider.future);

    expect(state.items.single.id, 't1');
    expect(state.nextCursor, 'eyJ');
    expect(state.hasMore, true);
  });

  test('loadMore appends the next page and updates the cursor', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], 'cur1'));
    when(() => repo.list(
        kind: null,
        categoryId: null,
        from: null,
        to: null,
        cursor: 'cur1')).thenAnswer((_) async => _page([_tx('t2')], null));
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await c.read(transactionsControllerProvider.notifier).loadMore();

    final state = c.read(transactionsControllerProvider).value!;
    expect(state.items.map((t) => t.id), ['t1', 't2']);
    expect(state.nextCursor, isNull);
    expect(state.hasMore, false);
  });

  test('loadMore is a no-op at the end of the list', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], null));
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await c.read(transactionsControllerProvider.notifier).loadMore();

    verifyNever(() => repo.list(
        kind: any(named: 'kind'),
        categoryId: any(named: 'categoryId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        cursor: 'anything'));
    expect(c.read(transactionsControllerProvider).value!.items.length, 1);
  });

  test('refresh reloads the first page', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], 'eyJ'));
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await c.read(transactionsControllerProvider.notifier).refresh();

    expect(c.read(transactionsControllerProvider).value!.items.single.id, 't1');
  });

  test('create optimistically prepends, then swaps in the server item',
      () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], null));
    when(() => repo.create(
          amountCents: 500,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
        )).thenAnswer((_) async => _tx('t2'));
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await c.read(transactionsControllerProvider.notifier).create(
          amountCents: 500,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
        );

    expect(c.read(transactionsControllerProvider).value!.items.map((t) => t.id),
        ['t2', 't1']);
  });

  test('create rolls back and rethrows on failure', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], null));
    when(() => repo.create(
          amountCents: 500,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
        )).thenThrow(const ConflictFailure());
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await expectLater(
      c.read(transactionsControllerProvider.notifier).create(
            amountCents: 500,
            kind: CategoryKind.expense,
            categoryId: 'c1',
            occurredAt: DateTime(2026, 6, 30),
          ),
      throwsA(isA<ConflictFailure>()),
    );
    expect(c.read(transactionsControllerProvider).value!.items.map((t) => t.id),
        ['t1']); // rolled back
  });

  test('create outside the active filter leaves the visible list untouched',
      () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], null));
    // Switch to an income-only filter.
    when(() => repo.list(
            kind: CategoryKind.income, categoryId: null, from: null, to: null))
        .thenAnswer((_) async => _page([_tx('t9', kind: CategoryKind.income)], null));
    when(() => repo.create(
          amountCents: 500,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
        )).thenAnswer((_) async => _tx('t2'));
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);
    await c.read(transactionsControllerProvider.notifier).setFilter(
        (kind: CategoryKind.income, categoryId: null, from: null, to: null));

    await c.read(transactionsControllerProvider.notifier).create(
          amountCents: 500,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
        );

    // The expense doesn't match the income filter → list stays as-is.
    expect(c.read(transactionsControllerProvider).value!.items.map((t) => t.id),
        ['t9']);
    verify(() => repo.create(
          amountCents: 500,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
        )).called(1);
  });

  test('update swaps the edited transaction in place', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1'), _tx('t2')], null));
    final edited = _tx('t1').copyWith(amountCents: 9999);
    when(() => repo.update(
          't1',
          amountCents: 9999,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
          clearDescription: true,
        )).thenAnswer((_) async => edited);
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await c.read(transactionsControllerProvider.notifier).edit(edited);

    final items = c.read(transactionsControllerProvider).value!.items;
    expect(items.firstWhere((t) => t.id == 't1').amountCents, 9999);
  });

  test('remove optimistically drops the row, rolls back on failure', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1'), _tx('t2')], null));
    when(() => repo.delete('t1')).thenThrow(const ConflictFailure());
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await expectLater(
      c.read(transactionsControllerProvider.notifier).remove('t1'),
      throwsA(isA<ConflictFailure>()),
    );
    expect(c.read(transactionsControllerProvider).value!.items.map((t) => t.id),
        ['t1', 't2']); // rolled back
  });

  test('setFilter refetches page one with the new filter', () async {
    final repo = _MockRepo();
    _stubFirstPage(repo, _page([_tx('t1')], null));
    when(() => repo.list(
            kind: CategoryKind.income, categoryId: null, from: null, to: null))
        .thenAnswer((_) async => _page([_tx('t9', kind: CategoryKind.income)], null));
    final c = _container(repo);
    await c.read(transactionsControllerProvider.future);

    await c.read(transactionsControllerProvider.notifier).setFilter(
        (kind: CategoryKind.income, categoryId: null, from: null, to: null));

    expect(c.read(transactionsControllerProvider).value!.items.single.id, 't9');
    verify(() => repo.list(
            kind: CategoryKind.income, categoryId: null, from: null, to: null))
        .called(1);
  });
}
