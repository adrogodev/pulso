import 'package:flutter/services.dart';

import '../../domain/models/opened_audio.dart';

/// Puente con `MainActivity`, que guarda el audio recibido por "Abrir con" o
/// "Compartir" hasta que Dart lo pide.
///
/// Android solo avisa con `audioAvailable`; el audio siempre se retira con
/// [take], así un mismo audio nunca se reproduce dos veces.
class OpenedAudioChannel {
  static const String name = 'dev.adrogo.pulso/opened_audio';

  final MethodChannel _channel = const MethodChannel(name);

  /// Retira el audio pendiente, o null si la app se abrió de forma normal.
  Future<OpenedAudio?> take() async {
    final data = await _channel.invokeMapMethod<String, Object?>(
      'takeOpenedAudio',
    );
    final uri = data?['uri'];
    if (uri is! String || uri.isEmpty) return null;
    final displayName = data?['displayName'];
    return OpenedAudio(
      uri: uri,
      displayName: displayName is String ? displayName : null,
    );
  }

  /// Llama a [callback] cada vez que llega un audio con la app ya abierta.
  void onAvailable(void Function() callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'audioAvailable') callback();
    });
  }
}
