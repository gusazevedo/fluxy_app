import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum CategoryKind {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required CategoryKind kind,
    required bool archived,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
