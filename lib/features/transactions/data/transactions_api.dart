// lib/features/transactions/data/transactions_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/time/api_date.dart';
import '../../categories/domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transactions_page.dart';

class TransactionsApi {
  TransactionsApi(this._dio);
  final Dio _dio;

  /// `GET /transactions` — keyset pagination. Only sends the params that are set.
  Future<TransactionsPage> list({
    DateTime? from,
    DateTime? to,
    String? categoryId,
    CategoryKind? kind,
    int limit = 20,
    String? cursor,
  }) async {
    final res = await _dio.get('/transactions', queryParameters: {
      if (from != null) 'from': apiDateToString(from),
      if (to != null) 'to': apiDateToString(to),
      'categoryId': ?categoryId,
      if (kind != null) 'kind': kind.name,
      'limit': limit,
      'cursor': ?cursor,
    });
    final data = res.data as Map<String, dynamic>;
    return TransactionsPage(
      items: (data['items'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<Transaction> create({
    required int amountCents,
    required CategoryKind kind,
    required String categoryId,
    required DateTime occurredAt,
    String? description,
  }) async {
    final res = await _dio.post('/transactions', data: {
      'amountCents': amountCents,
      'kind': kind.name,
      'categoryId': categoryId,
      'occurredAt': apiDateToString(occurredAt),
      'description': ?description,
    });
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Transaction> get(String id) async {
    final res = await _dio.get('/transactions/$id');
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// `PATCH /transactions/:id` — every field optional. Pass [clearDescription]
  /// to send `description: null` (clears it); otherwise a null [description] is
  /// simply omitted from the body.
  Future<Transaction> update(
    String id, {
    int? amountCents,
    CategoryKind? kind,
    String? categoryId,
    DateTime? occurredAt,
    String? description,
    bool clearDescription = false,
  }) async {
    final res = await _dio.patch('/transactions/$id', data: {
      'amountCents': ?amountCents,
      if (kind != null) 'kind': kind.name,
      'categoryId': ?categoryId,
      if (occurredAt != null) 'occurredAt': apiDateToString(occurredAt),
      if (clearDescription)
        'description': null
      else
        'description': ?description,
    });
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/transactions/$id');
}

final transactionsApiProvider =
    Provider<TransactionsApi>((ref) => TransactionsApi(ref.watch(dioProvider)));
