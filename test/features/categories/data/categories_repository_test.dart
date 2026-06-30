// test/features/categories/data/categories_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/categories/data/categories_api.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements CategoriesApi {}

DioException _dioErr(int code) => DioException(
      requestOptions: RequestOptions(path: '/categories'),
      response: Response(
          requestOptions: RequestOptions(path: '/categories'), statusCode: code),
      type: DioExceptionType.badResponse,
    );

Category _cat = Category(
  id: 'c1',
  name: 'Mercado',
  kind: CategoryKind.expense,
  archived: false,
  createdAt: DateTime.utc(2026, 1, 2),
);

void main() {
  late _MockApi api;
  late CategoriesRepository repo;

  setUp(() {
    api = _MockApi();
    repo = CategoriesRepository(api);
  });

  test('list delegates to the api', () async {
    when(() => api.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat]);

    final out = await repo.list(kind: CategoryKind.expense);

    expect(out.single.id, 'c1');
  });

  test('create maps a 409 to ConflictFailure', () async {
    when(() => api.create('Mercado', CategoryKind.expense)).thenThrow(_dioErr(409));

    expect(
      () => repo.create('Mercado', CategoryKind.expense),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('delete maps a 409 to ConflictFailure', () async {
    when(() => api.delete('c1')).thenThrow(_dioErr(409));

    expect(() => repo.delete('c1'), throwsA(isA<ConflictFailure>()));
  });

  test('rename maps a network error to NetworkFailure', () async {
    when(() => api.rename('c1', 'X')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/categories/c1'),
      type: DioExceptionType.connectionError,
    ));

    expect(() => repo.rename('c1', 'X'), throwsA(isA<NetworkFailure>()));
  });
}
