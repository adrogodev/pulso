import 'package:flutter/foundation.dart';

import '../../../../shared/base_domain/error/failures.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';

/// Ejecuta la búsqueda de una fuente en línea y traduce sus errores a
/// [NetworkFailure]. Una búsqueda vacía no consulta la red.
Future<Result<List<Track>>> guardedSearch(
  String source,
  String query,
  Future<List<Track>> Function(String query) search,
) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const Result.ok([]);

  try {
    return Result.ok(List.unmodifiable(await search(trimmed)));
  } on FormatException catch (e) {
    // Un cambio en el formato de la API no es culpa de la conexión del
    // usuario: se informa distinto y queda registrado para diagnosticarlo.
    debugPrint('$source devolvió una respuesta no válida: $e');
    return Result.err(
      NetworkFailure(
        '$source devolvió una respuesta inesperada. Inténtalo más tarde.',
        cause: e,
      ),
    );
  } catch (e) {
    debugPrint('Falló la búsqueda en $source: $e');
    return Result.err(
      NetworkFailure(
        'No se pudo buscar en línea. Revisa tu conexión a internet.',
        cause: e,
      ),
    );
  }
}
