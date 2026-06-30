import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';

void main() {
  test('fromJson parses kind enum, archived flag and createdAt', () {
    final c = Category.fromJson(const {
      'id': 'c1',
      'name': 'Mercado',
      'kind': 'expense',
      'archived': false,
      'createdAt': '2026-01-02T03:04:05.000Z',
    });

    expect(c.id, 'c1');
    expect(c.name, 'Mercado');
    expect(c.kind, CategoryKind.expense);
    expect(c.archived, false);
    expect(c.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  test('CategoryKind.name matches the API query value', () {
    expect(CategoryKind.expense.name, 'expense');
    expect(CategoryKind.income.name, 'income');
  });
}
