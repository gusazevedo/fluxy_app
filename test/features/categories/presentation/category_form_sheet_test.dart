// test/features/categories/presentation/category_form_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/categories_strings.dart';
import 'package:fluxy_app/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: false,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Future<void> _pump(WidgetTester tester, _MockRepo repo) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(
      home: Scaffold(body: CategoryFormSheet(initialKind: CategoryKind.expense)),
    ),
  ));
}

void main() {
  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  testWidgets('blank name shows the required error and does not call create',
      (tester) async {
    final repo = _MockRepo();
    await _pump(tester, repo);

    await tester.tap(find.text(CategoriesStrings.create));
    await tester.pump();

    expect(find.text(CategoriesStrings.nameRequired), findsOneWidget);
    verifyNever(() => repo.create(any(), any()));
  });

  testWidgets('valid name calls create with the selected kind', (tester) async {
    final repo = _MockRepo();
    // controller.create needs the initial list to optimistically prepend onto.
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);
    when(() => repo.create('Lazer', CategoryKind.expense))
        .thenAnswer((_) async => _cat('c2', 'Lazer'));
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'Lazer');
    await tester.tap(find.text(CategoriesStrings.create));
    await tester.pumpAndSettle();

    verify(() => repo.create('Lazer', CategoryKind.expense)).called(1);
  });
}
