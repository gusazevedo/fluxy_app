// lib/core/error/failure.dart
sealed class Failure {
  final String message;
  final Map<String, List<String>> fields;
  const Failure(this.message, {this.fields = const {}});
}

class NetworkFailure extends Failure {
  const NetworkFailure([String m = 'Sem conexão. Verifique sua internet.']) : super(m);
}
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String m = 'Sua sessão expirou.']) : super(m);
}
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([String m = 'Acesso negado.']) : super(m);
}
class NotFoundFailure extends Failure {
  const NotFoundFailure([String m = 'Não encontrado.']) : super(m);
}
class ValidationFailure extends Failure {
  const ValidationFailure(String m, {Map<String, List<String>> fields = const {}})
      : super(m, fields: fields);
}
class ConflictFailure extends Failure {
  const ConflictFailure([String m = 'Conflito.']) : super(m);
}
class ServerFailure extends Failure {
  const ServerFailure([String m = 'Algo deu errado. Tente novamente.']) : super(m);
}
class UnknownFailure extends Failure {
  const UnknownFailure([String m = 'Erro inesperado.']) : super(m);
}
