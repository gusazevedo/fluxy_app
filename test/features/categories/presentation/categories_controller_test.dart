import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/categories_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name, {bool archived = false}) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: archived,
      createdAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container(_MockRepo repo) {
  final c = ProviderContainer(
    overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('build loads the default (expense, not archived) list', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    final c = _container(repo);

    final list = await c.read(categoriesControllerProvider.future);

    expect(list.single.name, 'Mercado');
  });

  test('create optimistically prepends, then replaces with the server item',
      () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.create('Lazer', CategoryKind.expense))
        .thenAnswer((_) async => _cat('c2', 'Lazer'));
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await c.read(categoriesControllerProvider.notifier)
        .create('Lazer', CategoryKind.expense);

    final names = c.read(categoriesControllerProvider).value!.map((e) => e.name);
    expect(names, ['Lazer', 'Mercado']);
  });

  test('create rolls back and rethrows on failure', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.create('Dup', CategoryKind.expense))
        .thenThrow(const ConflictFailure());
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await expectLater(
      c.read(categoriesControllerProvider.notifier)
          .create('Dup', CategoryKind.expense),
      throwsA(isA<ConflictFailure>()),
    );
    final names = c.read(categoriesControllerProvider).value!.map((e) => e.name);
    expect(names, ['Mercado']); // rolled back
  });

  test('remove optimistically drops the row, rolls back on failure', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado'), _cat('c2', 'Lazer')]);
    when(() => repo.delete('c1')).thenThrow(const ConflictFailure());
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await expectLater(
      c.read(categoriesControllerProvider.notifier).remove('c1'),
      throwsA(isA<ConflictFailure>()),
    );
    final ids = c.read(categoriesControllerProvider).value!.map((e) => e.id);
    expect(ids, ['c1', 'c2']); // rolled back
  });

  test('setFilter refetches with the new kind', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .thenAnswer((_) async => [_cat('c9', 'Salário')]);
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await c.read(categoriesControllerProvider.notifier)
        .setFilter(kind: CategoryKind.income);

    expect(c.read(categoriesControllerProvider).value!.single.name, 'Salário');
    verify(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .called(1);
  });
}
