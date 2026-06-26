// lib/core/error/failure.dart
sealed class Failure {
  final String message;
  final Map<String, List<String>> fields;
  const Failure(this.message, {this.fields = const {}});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.m = 'Sem conexão. Verifique sua internet.']);
}
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.m = 'Sua sessão expirou.']);
}
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.m = 'Acesso negado.']);
}
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.m = 'Não encontrado.']);
}
class ValidationFailure extends Failure {
  const ValidationFailure(super.m, {super.fields});
}
class ConflictFailure extends Failure {
  const ConflictFailure([super.m = 'Conflito.']);
}
class ServerFailure extends Failure {
  const ServerFailure([super.m = 'Algo deu errado. Tente novamente.']);
}
class UnknownFailure extends Failure {
  const UnknownFailure([super.m = 'Erro inesperado.']);
}
