// lib/features/categories/data/categories_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../domain/category.dart';
import 'categories_api.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final CategoriesApi _api;

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      throw failureFromDio(e);
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  Future<List<Category>> list({CategoryKind? kind, bool includeArchived = false}) =>
      _guard(() => _api.list(kind: kind, includeArchived: includeArchived));

  Future<Category> create(String name, CategoryKind kind) =>
      _guard(() => _api.create(name, kind));

  Future<Category> get(String id) => _guard(() => _api.get(id));

  Future<Category> rename(String id, String newName) =>
      _guard(() => _api.rename(id, newName));

  Future<void> delete(String id) => _guard(() => _api.delete(id));
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(categoriesApiProvider)),
);
