// test/features/categories/presentation/categories_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/categories_strings.dart';
import 'package:fluxy_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:fluxy_app/features/categories/presentation/widgets/category_row.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name, {bool archived = false}) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: archived,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Widget _host(_MockRepo repo) => ProviderScope(
      overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: CategoriesScreen())),
    );

void main() {
  testWidgets('renders the kind toggle and category rows', (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);

    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    expect(find.text(CategoriesStrings.tab), findsOneWidget);
    expect(find.text(CategoriesStrings.expense), findsWidgets); // toggle segment
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
  });

  testWidgets('empty list shows the empty state', (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);

    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    expect(find.text(CategoriesStrings.empty), findsOneWidget);
  });

  testWidgets('tapping Receita refetches with the income kind', (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);

    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text(CategoriesStrings.income));
    await tester.pumpAndSettle();

    verify(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .called(1);
  });
}
