import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'equalizer_engine.dart';

/// Motor de ecualización real basado en [AndroidEqualizer] de just_audio.
class JustAudioEqualizerEngine implements EqualizerEngine {
  final AndroidEqualizer _equalizer;

  JustAudioEqualizerEngine(this._equalizer);

  /// Los parámetros dependen de que el reproductor active el efecto; si eso
  /// no ocurre, se corta la espera en vez de dejar la pantalla cargando.
  static const Duration _parametersTimeout = Duration(seconds: 8);

  Future<AndroidEqualizerParameters> _parameters() =>
      _equalizer.parameters.timeout(_parametersTimeout);

  @override
  Future<List<EqualizerBandInfo>> loadBands() async {
    // Plataforma real y no defaultTargetPlatform, que en los tests simula
    // Android sin el efecto nativo.
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('El ecualizador solo existe en Android');
    }
    final parameters = await _parameters();
    return [
      for (final band in parameters.bands)
        EqualizerBandInfo(
          index: band.index,
          centerHz: band.centerFrequency,
          minDb: parameters.minDecibels,
          maxDb: parameters.maxDecibels,
        ),
    ];
  }

  @override
  Future<void> setBandGain(int index, double gainDb) async {
    final parameters = await _parameters();
    await parameters.bands.firstWhere((b) => b.index == index).setGain(gainDb);
  }

  @override
  Future<void> setEnabled(bool enabled) => _equalizer.setEnabled(enabled);
}
