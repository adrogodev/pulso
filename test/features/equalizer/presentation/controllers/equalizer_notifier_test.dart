import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_band.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_settings.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_unavailable_failure.dart';
import 'package:pulso/features/equalizer/domain/services/equalizer_service.dart';
import 'package:pulso/features/equalizer/presentation/controllers/equalizer_notifier.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

class _FakeEqualizerService implements EqualizerService {
  bool unavailable = false;
  bool initialEnabled = true;
  final List<EqualizerBand> initialBands = const [
    EqualizerBand(index: 0, centerHz: 60, minDb: -15, maxDb: 15, gainDb: 4),
    EqualizerBand(index: 1, centerHz: 1000, minDb: -15, maxDb: 15),
  ];
  final List<String> calls = [];
  List<double>? savedGains;
  bool failWrites = false;

  static const _writeFailure = Result<void>.err(
    EqualizerUnavailableFailure('no se pudo aplicar'),
  );

  @override
  Future<Result<EqualizerSettings>> load() async {
    if (unavailable) {
      return const Result.err(EqualizerUnavailableFailure('no disponible'));
    }
    return Result.ok(
      EqualizerSettings(enabled: initialEnabled, bands: initialBands),
    );
  }

  @override
  Future<Result<void>> setEnabled(bool enabled) async {
    calls.add('enabled:$enabled');
    return failWrites ? _writeFailure : const Result.ok(null);
  }

  @override
  Future<Result<void>> setBandGain(int index, double gainDb) async {
    calls.add('gain:$index:$gainDb');
    return failWrites ? _writeFailure : const Result.ok(null);
  }

  @override
  Future<Result<void>> saveGains(List<double> gainsDb) async {
    if (failWrites) return _writeFailure;
    savedGains = gainsDb;
    return const Result.ok(null);
  }
}

void main() {
  late _FakeEqualizerService service;
  late ProviderContainer container;

  setUp(() {
    service = _FakeEqualizerService();
    container = ProviderContainer(
      overrides: [equalizerServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  });

  EqualizerNotifier notifier() =>
      container.read(equalizerNotifierProvider.notifier);
  EqualizerState state() => container.read(equalizerNotifierProvider);

  group('EqualizerNotifier', () {
    test('load carga bandas y estado de activación del servicio', () async {
      await notifier().load();

      expect(state().isLoading, isFalse);
      expect(state().isSupported, isTrue);
      expect(state().enabled, isTrue);
      expect(state().bands.map((b) => b.gainDb), [4, 0]);
    });

    test('revierte el interruptor y avisa si no se pudo aplicar', () async {
      await notifier().load();
      service.failWrites = true;

      await notifier().setEnabled(false);

      expect(state().enabled, isTrue);
      expect(state().errorMessage, 'no se pudo aplicar');
    });

    test('revierte la ganancia de la banda si no se pudo aplicar', () async {
      await notifier().load();
      service.failWrites = true;

      await notifier().setBandGain(0, 10);

      expect(state().bands.first.gainDb, 4);
      expect(state().errorMessage, 'no se pudo aplicar');
    });

    test('avisa si no se pudieron guardar las ganancias', () async {
      await notifier().load();
      service.failWrites = true;

      await notifier().commitGains();

      expect(state().errorMessage, 'no se pudo aplicar');
    });

    test('load marca no soportado y conserva el mensaje si falla', () async {
      service.unavailable = true;

      await notifier().load();

      expect(state().isLoading, isFalse);
      expect(state().isSupported, isFalse);
      expect(state().errorMessage, 'no disponible');
    });

    test('setEnabled actualiza el estado y llama al servicio', () async {
      await notifier().load();

      await notifier().setEnabled(false);

      expect(state().enabled, isFalse);
      expect(service.calls, ['enabled:false']);
    });

    test('setBandGain actualiza el estado y llama al servicio', () async {
      await notifier().load();

      await notifier().setBandGain(1, 6);

      expect(state().bands[1].gainDb, 6);
      expect(service.calls, ['gain:1:6.0']);
      expect(service.savedGains, isNull);
    });

    test('commitGains persiste las ganancias actuales', () async {
      await notifier().load();
      await notifier().setBandGain(1, 6);

      await notifier().commitGains();

      expect(service.savedGains, [4, 6]);
    });

    test('reset deja todas las bandas en 0 dB y persiste', () async {
      await notifier().load();

      await notifier().reset();

      expect(state().bands.map((b) => b.gainDb), [0, 0]);
      expect(service.calls, ['gain:0:0.0', 'gain:1:0.0']);
      expect(service.savedGains, [0, 0]);
    });
  });
}
