import 'package:flutter/foundation.dart';

/// Audio que otra app le pidió a Pulso abrir desde el menú "Abrir con" o
/// "Compartir" de Android.
@immutable
class OpenedAudio {
  final String uri;

  /// Nombre del archivo según quien lo comparte; no siempre viene.
  final String? displayName;

  const OpenedAudio({required this.uri, this.displayName});
}
