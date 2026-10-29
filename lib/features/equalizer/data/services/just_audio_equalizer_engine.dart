import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'equalizer_engine.dart';

/// Motor de ecualización real basado en [AndroidEqualizer] de just_audio.
class JustAudioEqualizerEngine implements EqualizerEngine {
  final AndroidEqualizer _equalizer;

  JustAudioEqualizerEngine(this._equalizer);

  @override
  Future<List<EqualizerBandInfo>> loadBands() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('El ecualizador solo existe en Android');
    }
    final parameters = await _equalizer.parameters;
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
    final parameters = await _equalizer.parameters;
    await parameters.bands.firstWhere((b) => b.index == index).setGain(gainDb);
  }

  @override
  Future<void> setEnabled(bool enabled) => _equalizer.setEnabled(enabled);
}
