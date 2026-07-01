// lib/features/transactions/presentation/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/domain/category.dart';

/// Maps categoryId → display name for rendering transaction rows. Includes
/// archived categories so historical transactions still show their name.
final categoryNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final cats =
      await ref.watch(categoriesRepositoryProvider).list(includeArchived: true);
  return {for (final c in cats) c.id: c.name};
});

/// Active (non-archived) categories of a given [kind], for the create/edit
/// picker. A transaction can only reference an active category of its own kind.
final activeCategoriesProvider =
    FutureProvider.family<List<Category>, CategoryKind>((ref, kind) {
  return ref
      .watch(categoriesRepositoryProvider)
      .list(kind: kind, includeArchived: false);
});

/// All active categories (both kinds), for the list filter's category dropdown.
final allActiveCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).list(includeArchived: false);
});
