import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/equalizer/data/services/android_equalizer_service.dart';
import 'package:pulso/features/equalizer/data/services/equalizer_engine.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_unavailable_failure.dart';
import 'package:pulso/features/settings/domain/services/settings_repository.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

class _FakeEngine implements EqualizerEngine {
  bool unavailable = false;
  final List<EqualizerBandInfo> bands = const [
    EqualizerBandInfo(index: 0, centerHz: 60, minDb: -15, maxDb: 15),
    EqualizerBandInfo(index: 1, centerHz: 1000, minDb: -15, maxDb: 15),
  ];
  final Map<int, double> appliedGains = {};
  bool? appliedEnabled;

  @override
  Future<List<EqualizerBandInfo>> loadBands() async {
    if (unavailable) throw UnsupportedError('sin ecualizador');
    return bands;
  }

  @override
  Future<void> setBandGain(int index, double gainDb) async {
    if (unavailable) throw UnsupportedError('sin ecualizador');
    appliedGains[index] = gainDb;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (unavailable) throw UnsupportedError('sin ecualizador');
    appliedEnabled = enabled;
  }
}

class _FakeSettings implements SettingsRepository {
  final Map<String, String> store = {};

  @override
  Future<Result<String?>> getPreference(String key) async =>
      Result.ok(store[key]);

  @override
  Future<Result<void>> setPreference(String key, String value) async {
    store[key] = value;
    return const Result.ok(null);
  }

  @override
  Future<Result<Map<String, dynamic>?>> getLastSession() async =>
      const Result.ok(null);

  @override
  Future<Result<void>> saveLastSession(String trackId, int positionMs) async =>
      const Result.ok(null);
}

void main() {
  late _FakeEngine engine;
  late _FakeSettings settings;
  late AndroidEqualizerService service;

  setUp(() {
    engine = _FakeEngine();
    settings = _FakeSettings();
    service = AndroidEqualizerService(engine: engine, settings: settings);
  });

  group('AndroidEqualizerService', () {
    test('sin valores guardados carga bandas planas y desactivado', () async {
      final result = await service.load();

      final data = result.dataOrNull!;
      expect(data.enabled, isFalse);
      expect(data.bands.map((b) => b.gainDb), [0, 0]);
      expect(data.bands.map((b) => b.centerHz), [60, 1000]);
    });

    test('reaplica y devuelve los valores guardados, con clamp', () async {
      settings.store['eq_enabled'] = 'true';
      settings.store['eq_gains'] = '3.5,-40';

      final data = (await service.load()).dataOrNull!;

      expect(data.enabled, isTrue);
      expect(data.bands.map((b) => b.gainDb), [3.5, -15]);
      expect(engine.appliedGains, {0: 3.5, 1: -15});
      expect(engine.appliedEnabled, isTrue);
    });

    test('ignora ganancias guardadas con formato inválido', () async {
      settings.store['eq_gains'] = 'abc,2';

      final data = (await service.load()).dataOrNull!;

      expect(data.bands.map((b) => b.gainDb), [0, 2]);
    });

    test('setEnabled aplica y persiste', () async {
      await service.load();

      final result = await service.setEnabled(true);

      expect(result.isSuccess, isTrue);
      expect(engine.appliedEnabled, isTrue);
      expect(settings.store['eq_enabled'], 'true');
    });

    test('setBandGain aplica con clamp y no persiste', () async {
      await service.load();

      final result = await service.setBandGain(1, 99);

      expect(result.isSuccess, isTrue);
      expect(engine.appliedGains[1], 15);
      expect(settings.store.containsKey('eq_gains'), isFalse);
    });

    test('saveGains persiste una lista separada por comas', () async {
      await service.load();

      final result = await service.saveGains([1.5, -2]);

      expect(result.isSuccess, isTrue);
      expect(settings.store['eq_gains'], '1.5,-2.0');
    });

    test(
      'devuelve Result.err sin lanzar si la plataforma no lo ofrece',
      () async {
        engine.unavailable = true;

        final result = await service.load();

        expect(result.isError, isTrue);
        expect(result.failureOrNull, isA<EqualizerUnavailableFailure>());
        expect(
          result.failureOrNull!.message,
          'El ecualizador no está disponible en este dispositivo',
        );
      },
    );

    test('setEnabled devuelve Result.err si el motor falla', () async {
      engine.unavailable = true;

      final result = await service.setEnabled(true);

      expect(result.isError, isTrue);
    });
  });
}
