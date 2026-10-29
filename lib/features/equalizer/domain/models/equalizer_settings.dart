import 'equalizer_band.dart';

/// Estado completo del ecualizador: activación y bandas con su ganancia.
class EqualizerSettings {
  final bool enabled;
  final List<EqualizerBand> bands;

  const EqualizerSettings({required this.enabled, required this.bands});
}
