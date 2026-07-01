// test/features/transactions/data/transactions_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/data/transactions_api.dart';
import 'package:fluxy_app/features/transactions/data/transactions_repository.dart';
import 'package:fluxy_app/features/transactions/domain/transaction.dart';
import 'package:fluxy_app/features/transactions/domain/transactions_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements TransactionsApi {}

DioException _dioErr(int code) => DioException(
      requestOptions: RequestOptions(path: '/transactions'),
      response: Response(
          requestOptions: RequestOptions(path: '/transactions'), statusCode: code),
      type: DioExceptionType.badResponse,
    );

Transaction _tx = Transaction(
  id: 't1',
  amountCents: 1234,
  kind: CategoryKind.expense,
  categoryId: 'c1',
  description: null,
  occurredAt: DateTime(2026, 6, 30),
  createdAt: DateTime.utc(2026, 6, 30, 12),
);

void main() {
  late _MockApi api;
  late TransactionsRepository repo;

  setUp(() {
    api = _MockApi();
    repo = TransactionsRepository(api);
  });

  test('list delegates to the api', () async {
    when(() => api.list(limit: 20)).thenAnswer(
        (_) async => TransactionsPage(items: [_tx], nextCursor: null));

    final page = await repo.list();

    expect(page.items.single.id, 't1');
  });

  test('create maps a 409 (archived/kind mismatch) to ConflictFailure', () async {
    when(() => api.create(
          amountCents: 100,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
        )).thenThrow(_dioErr(409));

    expect(
      () => repo.create(
        amountCents: 100,
        kind: CategoryKind.expense,
        categoryId: 'c1',
        occurredAt: DateTime(2026, 6, 30),
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('create maps a 400 (invalid amount) to ValidationFailure', () async {
    when(() => api.create(
          amountCents: 0,
          kind: CategoryKind.expense,
          categoryId: 'c1',
          occurredAt: DateTime(2026, 6, 30),
          description: null,
        )).thenThrow(_dioErr(400));

    expect(
      () => repo.create(
        amountCents: 0,
        kind: CategoryKind.expense,
        categoryId: 'c1',
        occurredAt: DateTime(2026, 6, 30),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('delete maps a 404 to NotFoundFailure', () async {
    when(() => api.delete('t1')).thenThrow(_dioErr(404));

    expect(() => repo.delete('t1'), throwsA(isA<NotFoundFailure>()));
  });

  test('list maps a connection error to NetworkFailure', () async {
    when(() => api.list(limit: 20)).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/transactions'),
      type: DioExceptionType.connectionError,
    ));

    expect(() => repo.list(), throwsA(isA<NetworkFailure>()));
  });
}
