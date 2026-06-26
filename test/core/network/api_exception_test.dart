// test/core/network/api_exception_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/network/api_exception.dart';

DioException _http(int status, {dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  test('timeout -> NetworkFailure', () {
    final f = failureFromDio(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionTimeout,
    ));
    expect(f, isA<NetworkFailure>());
  });

  test('401 -> UnauthorizedFailure', () {
    expect(failureFromDio(_http(401)), isA<UnauthorizedFailure>());
  });

  test('422 -> ValidationFailure with extracted message', () {
    final f = failureFromDio(_http(422, body: {'message': 'E-mail inválido'}));
    expect(f, isA<ValidationFailure>());
    expect(f.message, 'E-mail inválido');
  });

  test('500 -> ServerFailure', () {
    expect(failureFromDio(_http(500)), isA<ServerFailure>());
  });

  test('message extraction falls back error -> detail', () {
    expect(failureFromDio(_http(400, body: {'error': 'Falhou'})).message, 'Falhou');
    expect(failureFromDio(_http(400, body: {'detail': 'Detalhe'})).message, 'Detalhe');
  });

  test('422 extracts field errors', () {
    final f = failureFromDio(_http(422, body: {
      'message': 'Inválido',
      'errors': {'email': ['obrigatório', 'inválido']}
    })) as ValidationFailure;
    expect(f.fields['email'], ['obrigatório', 'inválido']);
  });

  test('404 and 409 map to NotFound/Conflict', () {
    expect(failureFromDio(_http(404)), isA<NotFoundFailure>());
    expect(failureFromDio(_http(409)), isA<ConflictFailure>());
  });
}
