import 'package:flutter/foundation.dart';

/// Clase base inmutable para todos los fallos tipados de la aplicación.
@immutable
abstract class Failure {
  final String message;
  final Object? cause;

  const Failure(this.message, {this.cause});

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Causa: $cause)' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure &&
          other.runtimeType == runtimeType &&
          other.message == message);

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

/// Fallo derivado de permisos insuficientes o denegados.
class PermissionFailure extends Failure {
  final bool isPermanentlyDenied;

  const PermissionFailure(
    super.message, {
    this.isPermanentlyDenied = false,
    super.cause,
  });
}

/// Fallo al escanear o leer el almacenamiento multimedia local.
class AudioScanFailure extends Failure {
  const AudioScanFailure(super.message, {super.cause});
}

/// Fallo al inicializar o reproducir un recurso de audio.
class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message, {super.cause});
}

/// Fallo de persistencia o acceso a la base de datos local SQLite.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Fallo al consultar un servicio remoto (sin conexión, timeout o respuesta inválida).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

/// Fallo cuando un elemento no es encontrado.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}
