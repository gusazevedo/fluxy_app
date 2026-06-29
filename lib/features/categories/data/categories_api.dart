// lib/features/categories/data/categories_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/category.dart';

class CategoriesApi {
  CategoriesApi(this._dio);
  final Dio _dio;

  Future<List<Category>> list({CategoryKind? kind, bool includeArchived = false}) async {
    final res = await _dio.get('/categories', queryParameters: {
      if (kind != null) 'kind': kind.name,
      if (includeArchived) 'includeArchived': true,
    });
    return (res.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create(String name, CategoryKind kind) async {
    final res = await _dio.post('/categories', data: {'name': name, 'kind': kind.name});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> get(String id) async {
    final res = await _dio.get('/categories/$id');
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> rename(String id, String name) async {
    final res = await _dio.patch('/categories/$id', data: {'name': name});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/categories/$id');
}

final categoriesApiProvider =
    Provider<CategoriesApi>((ref) => CategoriesApi(ref.watch(dioProvider)));
