import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pulso/features/settings/presentation/controllers/settings_notifier.dart';

import '../../data/services/android_equalizer_service.dart';
import '../../data/services/just_audio_equalizer_engine.dart';
import '../../domain/models/equalizer_band.dart';
import '../../domain/services/equalizer_service.dart';

/// Instancia única del ecualizador de Android, compartida con el reproductor.
final androidEqualizerProvider = Provider<AndroidEqualizer>(
  (ref) => AndroidEqualizer(),
);

final equalizerServiceProvider = Provider<EqualizerService>((ref) {
  return AndroidEqualizerService(
    engine: JustAudioEqualizerEngine(ref.watch(androidEqualizerProvider)),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final equalizerNotifierProvider =
    NotifierProvider<EqualizerNotifier, EqualizerState>(EqualizerNotifier.new);

class EqualizerState {
  final bool isLoading;
  final bool isSupported;
  final bool enabled;
  final List<EqualizerBand> bands;
  final String? errorMessage;

  const EqualizerState({
    this.isLoading = true,
    this.isSupported = true,
    this.enabled = false,
    this.bands = const [],
    this.errorMessage,
  });

  EqualizerState copyWith({
    bool? isLoading,
    bool? isSupported,
    bool? enabled,
    List<EqualizerBand>? bands,
    String? errorMessage,
  }) {
    return EqualizerState(
      isLoading: isLoading ?? this.isLoading,
      isSupported: isSupported ?? this.isSupported,
      enabled: enabled ?? this.enabled,
      bands: bands ?? this.bands,
      errorMessage: errorMessage,
    );
  }
}

class EqualizerNotifier extends Notifier<EqualizerState> {
  EqualizerService get _service => ref.read(equalizerServiceProvider);

  @override
  EqualizerState build() => const EqualizerState();

  /// Lee las bandas del dispositivo y reaplica los valores guardados.
  /// Pensado también para llamarse una vez al arrancar la app.
  Future<void> load() async {
    final result = await _service.load();
    result.when(
      ok: (settings) {
        state = EqualizerState(
          isLoading: false,
          enabled: settings.enabled,
          bands: settings.bands,
        );
      },
      err: (failure) {
        state = EqualizerState(
          isLoading: false,
          isSupported: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _service.setEnabled(value);
  }

  /// Aplica la ganancia al instante; persistirla es tarea de [commitGains].
  Future<void> setBandGain(int index, double db) async {
    state = state.copyWith(
      bands: [
        for (final band in state.bands)
          band.index == index ? band.copyWith(gainDb: db) : band,
      ],
    );
    await _service.setBandGain(index, db);
  }

  /// Persiste las ganancias actuales (al soltar un slider).
  Future<void> commitGains() async {
    await _service.saveGains([for (final b in state.bands) b.gainDb]);
  }

  /// Deja todas las bandas en 0 dB y lo persiste.
  Future<void> reset() async {
    for (final band in state.bands) {
      await setBandGain(band.index, 0);
    }
    await commitGains();
  }
}
