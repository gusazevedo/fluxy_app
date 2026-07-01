// lib/features/transactions/presentation/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/data/categories_repository.dart';

/// Maps categoryId → display name for rendering transaction rows. Includes
/// archived categories so historical transactions still show their name.
final categoryNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final cats =
      await ref.watch(categoriesRepositoryProvider).list(includeArchived: true);
  return {for (final c in cats) c.id: c.name};
});
