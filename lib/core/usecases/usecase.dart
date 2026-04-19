import '../error/failures.dart';

/// Result ligero — reemplaza Either sin agregar dependencias.
/// Uso: `result.when(ok: (data) => ..., fail: (f) => ...)`
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) ok,
    required R Function(Failure failure) fail,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.data);
    if (self is Fail<T>) return fail(self.failure);
    throw StateError('Unreachable');
  }
}

class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

class Fail<T> extends Result<T> {
  final Failure failure;
  const Fail(this.failure);
}

/// Contrato base para todos los use cases.
abstract class UseCase<Output, Input> {
  Future<Result<Output>> call(Input input);
}

/// Para use cases sin input.
class NoParams {
  const NoParams();
}