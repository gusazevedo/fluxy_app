// test/features/transactions/presentation/transaction_form_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/data/transactions_repository.dart';
import 'package:fluxy_app/features/transactions/domain/transaction.dart';
import 'package:fluxy_app/features/transactions/domain/transactions_page.dart';
import 'package:fluxy_app/features/transactions/presentation/transactions_strings.dart';
import 'package:fluxy_app/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockCatRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: false,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Transaction _tx(String id) => Transaction(
      id: id,
      amountCents: 1234,
      kind: CategoryKind.expense,
      categoryId: 'c1',
      description: null,
      occurredAt: DateTime(2026, 6, 30),
      createdAt: DateTime.utc(2026, 6, 30, 12),
    );

Future<void> _pump(WidgetTester tester, _MockTxRepo tx, _MockCatRepo cat) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      transactionsRepositoryProvider.overrideWithValue(tx),
      categoriesRepositoryProvider.overrideWithValue(cat),
    ],
    child: const MaterialApp(home: Scaffold(body: TransactionFormSheet())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(CategoryKind.expense);
    registerFallbackValue(DateTime(2026));
  });

  testWidgets('blank amount + no category block submit', (tester) async {
    final tx = _MockTxRepo();
    final cat = _MockCatRepo();
    when(() => cat.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    await _pump(tester, tx, cat);

    await tester.tap(find.text(TransactionsStrings.create));
    await tester.pump();

    expect(find.text(TransactionsStrings.amountRequired), findsOneWidget);
    expect(find.text(TransactionsStrings.categoryRequired), findsOneWidget);
    verifyNever(() => tx.create(
          amountCents: any(named: 'amountCents'),
          kind: any(named: 'kind'),
          categoryId: any(named: 'categoryId'),
          occurredAt: any(named: 'occurredAt'),
          description: any(named: 'description'),
        ));
  });

  testWidgets('valid input creates with parsed cents and selected category',
      (tester) async {
    final tx = _MockTxRepo();
    final cat = _MockCatRepo();
    when(() => cat.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => tx.list(kind: null, categoryId: null, from: null, to: null))
        .thenAnswer(
            (_) async => const TransactionsPage(items: [], nextCursor: null));
    when(() => tx.create(
          amountCents: 1234,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: any(named: 'occurredAt'),
          description: null,
        )).thenAnswer((_) async => _tx('t1'));
    await _pump(tester, tx, cat);

    await tester.enterText(find.byType(TextField).first, '12,34');
    // Open the category dropdown and pick "Mercado".
    await tester.tap(find.text(TransactionsStrings.categoryHint));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(TransactionsStrings.create));
    await tester.pumpAndSettle();

    verify(() => tx.create(
          amountCents: 1234,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: any(named: 'occurredAt'),
          description: null,
        )).called(1);
  });
}
