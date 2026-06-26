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
}
