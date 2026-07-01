// test/features/transactions/data/transactions_api_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/transactions/data/transactions_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(String path, dynamic data, [int code = 200]) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: code,
      data: data,
    );

Map<String, dynamic> _json(String id, {String? description}) => {
      'id': id,
      'amountCents': 1234,
      'kind': 'expense',
      'categoryId': 'c1',
      'description': description,
      'occurredAt': '2026-06-30',
      'createdAt': '2026-06-30T12:00:00.000Z',
    };

void main() {
  late _MockDio dio;
  late TransactionsApi api;

  setUp(() {
    dio = _MockDio();
    api = TransactionsApi(dio);
  });

  test('list sends filters + limit and parses items + nextCursor', () async {
    when(() => dio.get('/transactions', queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _resp('/transactions', {
              'items': [_json('t1')],
              'nextCursor': 'eyJ',
            }));

    final page = await api.list(
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 30),
      categoryId: 'c1',
      kind: CategoryKind.expense,
      limit: 20,
      cursor: 'prev',
    );

    expect(page.items.single.id, 't1');
    expect(page.nextCursor, 'eyJ');
    verify(() => dio.get('/transactions', queryParameters: {
          'from': '2026-06-01',
          'to': '2026-06-30',
          'categoryId': 'c1',
          'kind': 'expense',
          'limit': 20,
          'cursor': 'prev',
        })).called(1);
  });

  test('list omits unset filters and the cursor', () async {
    when(() => dio.get('/transactions', queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async =>
            _resp('/transactions', {'items': const [], 'nextCursor': null}));

    final page = await api.list();

    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
    verify(() => dio.get('/transactions', queryParameters: {'limit': 20}))
        .called(1);
  });

  test('create posts the body with occurredAt as YYYY-MM-DD', () async {
    when(() => dio.post('/transactions', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/transactions', _json('t9'), 201));

    final t = await api.create(
      amountCents: 1234,
      kind: CategoryKind.expense,
      categoryId: 'c1',
      occurredAt: DateTime(2026, 6, 30),
      description: 'Almoço',
    );

    expect(t.id, 't9');
    verify(() => dio.post('/transactions', data: {
          'amountCents': 1234,
          'kind': 'expense',
          'categoryId': 'c1',
          'occurredAt': '2026-06-30',
          'description': 'Almoço',
        })).called(1);
  });

  test('create omits a null description', () async {
    when(() => dio.post('/transactions', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/transactions', _json('t9'), 201));

    await api.create(
      amountCents: 100,
      kind: CategoryKind.income,
      categoryId: 'c2',
      occurredAt: DateTime(2026, 6, 30),
    );

    verify(() => dio.post('/transactions', data: {
          'amountCents': 100,
          'kind': 'income',
          'categoryId': 'c2',
          'occurredAt': '2026-06-30',
        })).called(1);
  });

  test('update sends only the changed fields', () async {
    when(() => dio.patch('/transactions/t1', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/transactions/t1', _json('t1')));

    await api.update('t1', amountCents: 999);

    verify(() => dio.patch('/transactions/t1', data: {'amountCents': 999}))
        .called(1);
  });

  test('update with clearDescription sends description: null', () async {
    when(() => dio.patch('/transactions/t1', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/transactions/t1', _json('t1')));

    await api.update('t1', clearDescription: true);

    verify(() => dio.patch('/transactions/t1', data: {'description': null}))
        .called(1);
  });

  test('delete DELETEs the id', () async {
    when(() => dio.delete('/transactions/t1'))
        .thenAnswer((_) async => _resp('/transactions/t1', null, 204));

    await api.delete('t1');

    verify(() => dio.delete('/transactions/t1')).called(1);
  });
}
