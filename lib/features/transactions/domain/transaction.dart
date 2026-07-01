import 'package:freezed_annotation/freezed_annotation.dart';

import '../../categories/domain/category.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// A single income/expense entry.
///
/// `amountCents` is always a positive integer (cents); the sign comes from
/// [kind]. Reuses [CategoryKind] because a transaction's kind must match its
/// category's kind (see `CATEGORY_KIND_MISMATCH` in the API contract).
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required int amountCents,
    required CategoryKind kind,
    required String categoryId,
    required String? description,
    required DateTime occurredAt,
    required DateTime createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
