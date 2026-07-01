// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  amountCents: (json['amountCents'] as num).toInt(),
  kind: $enumDecode(_$CategoryKindEnumMap, json['kind']),
  categoryId: json['categoryId'] as String,
  description: json['description'] as String?,
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amountCents': instance.amountCents,
      'kind': _$CategoryKindEnumMap[instance.kind]!,
      'categoryId': instance.categoryId,
      'description': instance.description,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$CategoryKindEnumMap = {
  CategoryKind.expense: 'expense',
  CategoryKind.income: 'income',
};
