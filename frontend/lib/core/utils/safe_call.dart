import 'package:dartz/dartz.dart';
import '../errors/failures.dart';
import 'error_handler.dart';

/// Helper centralizado que envuelve llamadas async en try/catch/Either.
/// Elimina el boilerplate repetido en cada método de repositorio.
///
/// Uso:
/// ```dart
/// Future<Either<Failure, List<Model>>> getItems() =>
///     safeCall(() => dataSource.getItems(), 'Error cargando items');
/// ```
Future<Either<Failure, T>> safeCall<T>(
  Future<T> Function() call,
  String errorContext,
) async {
  try {
    final result = await call();
    return Right(result);
  } catch (e) {
    return Left(ServerFailure(
      message: ErrorHandler.getUserMessage(e, context: errorContext),
    ));
  }
}
