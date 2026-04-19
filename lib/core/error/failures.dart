/// Base para todos los errores de dominio.
/// Un `Failure` viaja desde repositorios hasta UI sin acoplarse a excepciones.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Error de conexión']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error inesperado']);
}