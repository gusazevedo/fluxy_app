// lib/features/categories/presentation/categories_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../data/categories_repository.dart';
import '../domain/category.dart';

typedef CategoryFilter = ({CategoryKind kind, bool includeArchived});

/// Owns the currently-viewed category list. A single notifier (not a family)
/// holding its own [filter]; `setFilter` refetches. Mutations are optimistic
/// and roll back + rethrow on a [Failure] so the screen can surface it.
class CategoriesController extends AsyncNotifier<List<Category>> {
  CategoryFilter _filter = (kind: CategoryKind.expense, includeArchived: false);
  CategoryFilter get filter => _filter;

  CategoriesRepository get _repo => ref.read(categoriesRepositoryProvider);

  @override
  Future<List<Category>> build() =>
      _repo.list(kind: _filter.kind, includeArchived: _filter.includeArchived);

  Future<void> setFilter({CategoryKind? kind, bool? includeArchived}) async {
    _filter = (
      kind: kind ?? _filter.kind,
      includeArchived: includeArchived ?? _filter.includeArchived,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.list(kind: _filter.kind, includeArchived: _filter.includeArchived),
    );
  }

  Future<void> create(String name, CategoryKind kind) async {
    final previous = state.value ?? const <Category>[];
    // A category of the other kind doesn't belong to the visible list; create it
    // without touching state (it appears when the user switches tab).
    if (kind != _filter.kind) {
      await _repo.create(name, kind);
      return;
    }
    final temp = Category(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kind: kind,
      archived: false,
      createdAt: DateTime.now(),
    );
    state = AsyncData([temp, ...previous]);
    try {
      final created = await _repo.create(name, kind);
      state = AsyncData([created, ...previous]);
    } on Failure {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> rename(String id, String newName) async {
    final previous = state.value ?? const <Category>[];
    state = AsyncData([
      for (final c in previous) c.id == id ? c.copyWith(name: newName) : c,
    ]);
    try {
      await _repo.rename(id, newName);
    } on Failure {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final previous = state.value ?? const <Category>[];
    state = AsyncData([for (final c in previous) if (c.id != id) c]);
    try {
      await _repo.delete(id);
    } on Failure {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<Category>>(
        CategoriesController.new);
