// lib/features/transactions/data/transactions_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../../categories/domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transactions_page.dart';
import 'transactions_api.dart';

class TransactionsRepository {
  TransactionsRepository(this._api);
  final TransactionsApi _api;

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

  Future<TransactionsPage> list({
    DateTime? from,
    DateTime? to,
    String? categoryId,
    CategoryKind? kind,
    int limit = 20,
    String? cursor,
  }) =>
      _guard(() => _api.list(
            from: from,
            to: to,
            categoryId: categoryId,
            kind: kind,
            limit: limit,
            cursor: cursor,
          ));

  Future<Transaction> create({
    required int amountCents,
    required CategoryKind kind,
    required String categoryId,
    required DateTime occurredAt,
    String? description,
  }) =>
      _guard(() => _api.create(
            amountCents: amountCents,
            kind: kind,
            categoryId: categoryId,
            occurredAt: occurredAt,
            description: description,
          ));

  Future<Transaction> get(String id) => _guard(() => _api.get(id));

  Future<Transaction> update(
    String id, {
    int? amountCents,
    CategoryKind? kind,
    String? categoryId,
    DateTime? occurredAt,
    String? description,
    bool clearDescription = false,
  }) =>
      _guard(() => _api.update(
            id,
            amountCents: amountCents,
            kind: kind,
            categoryId: categoryId,
            occurredAt: occurredAt,
            description: description,
            clearDescription: clearDescription,
          ));

  Future<void> delete(String id) => _guard(() => _api.delete(id));
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.watch(transactionsApiProvider)),
);
