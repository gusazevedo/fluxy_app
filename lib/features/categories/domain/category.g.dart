// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: json['id'] as String,
  name: json['name'] as String,
  kind: $enumDecode(_$CategoryKindEnumMap, json['kind']),
  archived: json['archived'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'kind': _$CategoryKindEnumMap[instance.kind]!,
  'archived': instance.archived,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$CategoryKindEnumMap = {
  CategoryKind.expense: 'expense',
  CategoryKind.income: 'income',
};
