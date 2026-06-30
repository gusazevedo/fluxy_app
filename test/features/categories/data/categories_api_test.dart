// test/features/categories/data/categories_api_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_api.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(String path, dynamic data, [int code = 200]) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: code,
      data: data,
    );

Map<String, dynamic> _json(String id, String name, String kind) => {
      'id': id,
      'name': name,
      'kind': kind,
      'archived': false,
      'createdAt': '2026-01-02T03:04:05.000Z',
    };

void main() {
  late _MockDio dio;
  late CategoriesApi api;

  setUp(() {
    dio = _MockDio();
    api = CategoriesApi(dio);
  });

  test('list passes kind + includeArchived as query params', () async {
    when(() => dio.get('/categories', queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _resp('/categories', [_json('c1', 'Mercado', 'expense')]));

    final out = await api.list(kind: CategoryKind.expense, includeArchived: true);

    expect(out.single.name, 'Mercado');
    verify(() => dio.get('/categories',
        queryParameters: {'kind': 'expense', 'includeArchived': true})).called(1);
  });

  test('list omits query params when unset', () async {
    when(() => dio.get('/categories', queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _resp('/categories', const []));

    await api.list();

    verify(() => dio.get('/categories', queryParameters: {})).called(1);
  });

  test('create posts {name, kind} and parses the result', () async {
    when(() => dio.post('/categories', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/categories', _json('c2', 'Salário', 'income'), 201));

    final c = await api.create('Salário', CategoryKind.income);

    expect(c.id, 'c2');
    expect(c.kind, CategoryKind.income);
    verify(() => dio.post('/categories', data: {'name': 'Salário', 'kind': 'income'}))
        .called(1);
  });

  test('rename PATCHes {name}', () async {
    when(() => dio.patch('/categories/c1', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/categories/c1', _json('c1', 'Compras', 'expense')));

    final c = await api.rename('c1', 'Compras');

    expect(c.name, 'Compras');
    verify(() => dio.patch('/categories/c1', data: {'name': 'Compras'})).called(1);
  });

  test('delete DELETEs the id', () async {
    when(() => dio.delete('/categories/c1'))
        .thenAnswer((_) async => _resp('/categories/c1', null));

    await api.delete('c1');

    verify(() => dio.delete('/categories/c1')).called(1);
  });
}
