// test/features/transactions/presentation/transactions_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/data/transactions_repository.dart';
import 'package:fluxy_app/features/transactions/domain/transaction.dart';
import 'package:fluxy_app/features/transactions/domain/transactions_page.dart';
import 'package:fluxy_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:fluxy_app/features/transactions/presentation/transactions_strings.dart';
import 'package:fluxy_app/features/transactions/presentation/widgets/transaction_row.dart';
import 'package:mocktail/mocktail.dart';

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockCatRepo extends Mock implements CategoriesRepository {}

Transaction _tx(String id, DateTime occurredAt, {String categoryId = 'c1'}) =>
    Transaction(
      id: id,
      amountCents: 1234,
      kind: CategoryKind.expense,
      categoryId: categoryId,
      description: null,
      occurredAt: occurredAt,
      createdAt: DateTime.utc(2026, 6, 30, 12),
    );

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: false,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Widget _host(_MockTxRepo tx, _MockCatRepo cat) => ProviderScope(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(tx),
        categoriesRepositoryProvider.overrideWithValue(cat),
      ],
      child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
    );

void main() {
  testWidgets('groups rows under day headers with category names',
      (tester) async {
    final tx = _MockTxRepo();
    final cat = _MockCatRepo();
    // Fixed past dates keep the day-header labels stable across clocks.
    when(() => tx.list(kind: null, categoryId: null, from: null, to: null))
        .thenAnswer((_) async => TransactionsPage(
              items: [
                _tx('t1', DateTime(2024, 3, 15)),
                _tx('t2', DateTime(2024, 3, 10)),
              ],
              nextCursor: null,
            ));
    when(() => cat.list(includeArchived: true))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);

    await tester.pumpWidget(_host(tx, cat));
    await tester.pumpAndSettle();

    expect(find.text(TransactionsStrings.tab), findsOneWidget);
    expect(find.byType(TransactionRow), findsNWidgets(2));
    expect(find.text('Mercado'), findsNWidgets(2));
    expect(find.text('15 mar 2024'), findsOneWidget); // day header
    expect(find.text('10 mar 2024'), findsOneWidget); // day header
  });

  testWidgets('empty list shows the empty state', (tester) async {
    final tx = _MockTxRepo();
    final cat = _MockCatRepo();
    when(() => tx.list(kind: null, categoryId: null, from: null, to: null))
        .thenAnswer(
            (_) async => const TransactionsPage(items: [], nextCursor: null));
    when(() => cat.list(includeArchived: true))
        .thenAnswer((_) async => const <Category>[]);

    await tester.pumpWidget(_host(tx, cat));
    await tester.pumpAndSettle();

    expect(find.text(TransactionsStrings.empty), findsOneWidget);
  });
}
