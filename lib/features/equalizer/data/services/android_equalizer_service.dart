import 'package:pulso/features/settings/domain/services/settings_repository.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

import '../../domain/models/equalizer_band.dart';
import '../../domain/models/equalizer_settings.dart';
import '../../domain/models/equalizer_unavailable_failure.dart';
import '../../domain/services/equalizer_service.dart';
import 'equalizer_engine.dart';

/// Implementación del ecualizador sobre un [EqualizerEngine] y las
/// preferencias existentes de [SettingsRepository].
class AndroidEqualizerService implements EqualizerService {
  static const String enabledKey = 'eq_enabled';
  static const String gainsKey = 'eq_gains';
  static const String unavailableMessage =
      'El ecualizador no está disponible en este dispositivo';

  final EqualizerEngine engine;
  final SettingsRepository settings;
  List<EqualizerBandInfo> _bands = const [];

  AndroidEqualizerService({required this.engine, required this.settings});

  @override
  Future<Result<EqualizerSettings>> load() async {
    try {
      _bands = await engine.loadBands();
      final enabled =
          (await settings.getPreference(enabledKey)).dataOrNull == 'true';
      final saved = _parseGains(
        (await settings.getPreference(gainsKey)).dataOrNull,
      );

      final bands = <EqualizerBand>[];
      for (var i = 0; i < _bands.length; i++) {
        final info = _bands[i];
        final gain = _clamp(info, i < saved.length ? saved[i] : 0);
        await engine.setBandGain(info.index, gain);
        bands.add(
          EqualizerBand(
            index: info.index,
            centerHz: info.centerHz,
            minDb: info.minDb,
            maxDb: info.maxDb,
            gainDb: gain,
          ),
        );
      }
      await engine.setEnabled(enabled);
      return Result.ok(EqualizerSettings(enabled: enabled, bands: bands));
    } catch (e) {
      return const Result.err(EqualizerUnavailableFailure(unavailableMessage));
    }
  }

  @override
  Future<Result<void>> setEnabled(bool enabled) async {
    try {
      await engine.setEnabled(enabled);
    } catch (e) {
      return const Result.err(EqualizerUnavailableFailure(unavailableMessage));
    }
    return settings.setPreference(enabledKey, enabled.toString());
  }

  @override
  Future<Result<void>> setBandGain(int index, double gainDb) async {
    try {
      final info = _bands.firstWhere((b) => b.index == index);
      await engine.setBandGain(index, _clamp(info, gainDb));
      return const Result.ok(null);
    } catch (e) {
      return const Result.err(EqualizerUnavailableFailure(unavailableMessage));
    }
  }

  @override
  Future<Result<void>> saveGains(List<double> gainsDb) {
    return settings.setPreference(gainsKey, gainsDb.join(','));
  }

  double _clamp(EqualizerBandInfo info, double gain) =>
      gain.clamp(info.minDb, info.maxDb).toDouble();

  List<double> _parseGains(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((part) => double.tryParse(part.trim()) ?? 0.0)
        .toList();
  }
}
