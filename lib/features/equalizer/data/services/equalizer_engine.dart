/// Descripción de una banda tal como la reporta el motor de audio.
class EqualizerBandInfo {
  final int index;
  final double centerHz;
  final double minDb;
  final double maxDb;

  const EqualizerBandInfo({
    required this.index,
    required this.centerHz,
    required this.minDb,
    required this.maxDb,
  });
}

/// Adaptador mínimo sobre el ecualizador de la plataforma, para poder
/// sustituirlo en pruebas. Las implementaciones pueden lanzar excepciones si
/// la plataforma no lo soporta; el servicio las convierte en `Result.err`.
abstract class EqualizerEngine {
  Future<List<EqualizerBandInfo>> loadBands();
  Future<void> setBandGain(int index, double gainDb);
  Future<void> setEnabled(bool enabled);
}
