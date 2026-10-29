import 'package:pulso/shared/base_domain/result/result.dart';

import '../models/equalizer_settings.dart';

/// Contrato del ecualizador: lectura de bandas, aplicación y persistencia.
abstract class EqualizerService {
  /// Lee las bandas del dispositivo, aplica los valores guardados y los devuelve.
  Future<Result<EqualizerSettings>> load();

  /// Activa o desactiva el ecualizador y persiste el valor.
  Future<Result<void>> setEnabled(bool enabled);

  /// Aplica la ganancia de una banda al instante, sin persistirla.
  Future<Result<void>> setBandGain(int index, double gainDb);

  /// Persiste las ganancias actuales (una por banda, en orden de índice).
  Future<Result<void>> saveGains(List<double> gainsDb);
}
