import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/domain/transaction.dart';

void main() {
  test('fromJson parses amount, kind, dates and description', () {
    final t = Transaction.fromJson(const {
      'id': 't1',
      'amountCents': 1234,
      'kind': 'expense',
      'categoryId': 'c1',
      'description': 'Almoço',
      'occurredAt': '2026-06-30',
      'createdAt': '2026-06-30T12:00:00.000Z',
    });

    expect(t.id, 't1');
    expect(t.amountCents, 1234);
    expect(t.kind, CategoryKind.expense);
    expect(t.categoryId, 'c1');
    expect(t.description, 'Almoço');
    expect(t.occurredAt, DateTime(2026, 6, 30));
    expect(t.createdAt, DateTime.utc(2026, 6, 30, 12));
  });

  test('fromJson tolerates a null description', () {
    final t = Transaction.fromJson(const {
      'id': 't2',
      'amountCents': 500000,
      'kind': 'income',
      'categoryId': 'c2',
      'description': null,
      'occurredAt': '2026-06-01',
      'createdAt': '2026-06-01T00:00:00.000Z',
    });

    expect(t.kind, CategoryKind.income);
    expect(t.description, isNull);
  });
}
