// test/features/transactions/presentation/transaction_filter_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/presentation/transactions_controller.dart';
import 'package:fluxy_app/features/transactions/presentation/transactions_strings.dart';
import 'package:fluxy_app/features/transactions/presentation/widgets/transaction_filter_bar.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name, CategoryKind kind) => Category(
      id: id,
      name: name,
      kind: kind,
      archived: false,
      createdAt: DateTime.utc(2026, 1, 1),
    );

const TransactionFilter _empty =
    (kind: null, categoryId: null, from: null, to: null);

Widget _host(_MockCatRepo cat, ValueChanged<TransactionFilter> onChanged) =>
    ProviderScope(
      overrides: [categoriesRepositoryProvider.overrideWithValue(cat)],
      child: MaterialApp(
        home: Scaffold(
          body: TransactionFilterBar(filter: _empty, onChanged: onChanged),
        ),
      ),
    );

void main() {
  testWidgets('kind toggle emits the selected kind', (tester) async {
    final cat = _MockCatRepo();
    when(() => cat.list(includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);
    TransactionFilter? captured;

    await tester.pumpWidget(_host(cat, (f) => captured = f));
    await tester.pumpAndSettle();

    await tester.tap(find.text(TransactionsStrings.income));
    await tester.pumpAndSettle();

    expect(captured?.kind, CategoryKind.income);
  });

  testWidgets('category dropdown emits the selected categoryId', (tester) async {
    final cat = _MockCatRepo();
    when(() => cat.list(includeArchived: false)).thenAnswer(
        (_) async => [_cat('c1', 'Mercado', CategoryKind.expense)]);
    TransactionFilter? captured;

    await tester.pumpWidget(_host(cat, (f) => captured = f));
    await tester.pumpAndSettle();

    await tester.tap(find.text(TransactionsStrings.filterCategoryAll));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();

    expect(captured?.categoryId, 'c1');
  });
}
