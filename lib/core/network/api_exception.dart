// lib/core/network/api_exception.dart
import 'package:dio/dio.dart';
import '../error/failure.dart';

String _extractMessage(dynamic body, String fallback) {
  if (body is Map) {
    for (final k in ['message', 'error', 'detail']) {
      final v = body[k];
      if (v is String && v.isNotEmpty) return v;
    }
  }
  return fallback;
}

Map<String, List<String>> _extractFields(dynamic body) {
  if (body is Map && body['errors'] is Map) {
    return (body['errors'] as Map).map((k, v) => MapEntry(
          k.toString(),
          (v is List) ? v.map((e) => e.toString()).toList() : [v.toString()],
        ));
  }
  return const {};
}

Failure failureFromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const UnknownFailure('Requisição cancelada.');
    default:
      break;
  }
  final status = e.response?.statusCode;
  final body = e.response?.data;
  switch (status) {
    case 400:
    case 422:
      return ValidationFailure(_extractMessage(body, 'Dados inválidos.'),
          fields: _extractFields(body));
    case 401:
      return UnauthorizedFailure(_extractMessage(body, 'Sua sessão expirou.'));
    case 403:
      return ForbiddenFailure(_extractMessage(body, 'Acesso negado.'));
    case 404:
      return NotFoundFailure(_extractMessage(body, 'Não encontrado.'));
    case 409:
      return ConflictFailure(_extractMessage(body, 'Conflito.'));
    default:
      if (status != null && status >= 500) {
        return ServerFailure(_extractMessage(body, 'Algo deu errado. Tente novamente.'));
      }
      return UnknownFailure(_extractMessage(body, 'Erro inesperado.'));
  }
}
