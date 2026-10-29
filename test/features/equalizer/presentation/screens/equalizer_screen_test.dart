import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_band.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_settings.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_unavailable_failure.dart';
import 'package:pulso/features/equalizer/domain/services/equalizer_service.dart';
import 'package:pulso/features/equalizer/presentation/controllers/equalizer_notifier.dart';
import 'package:pulso/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

class _FakeEqualizerService implements EqualizerService {
  bool unavailable = false;
  bool enabled = true;
  List<double>? savedGains;

  @override
  Future<Result<EqualizerSettings>> load() async {
    if (unavailable) {
      return const Result.err(EqualizerUnavailableFailure('no disponible'));
    }
    return Result.ok(
      EqualizerSettings(
        enabled: enabled,
        bands: const [
          EqualizerBand(
            index: 0,
            centerHz: 60,
            minDb: -15,
            maxDb: 15,
            gainDb: 3,
          ),
          EqualizerBand(index: 1, centerHz: 1000, minDb: -15, maxDb: 15),
          EqualizerBand(index: 2, centerHz: 14000, minDb: -15, maxDb: 15),
        ],
      ),
    );
  }

  bool failWrites = false;

  @override
  Future<Result<void>> setEnabled(bool value) async {
    if (failWrites) {
      return const Result.err(
        EqualizerUnavailableFailure('No se pudo aplicar el ecualizador'),
      );
    }
    enabled = value;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setBandGain(int index, double gainDb) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> saveGains(List<double> gainsDb) async {
    savedGains = gainsDb;
    return const Result.ok(null);
  }
}

Future<void> _pump(WidgetTester tester, _FakeEqualizerService service) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [equalizerServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(home: EqualizerScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EqualizerScreen', () {
    testWidgets('muestra un slider por banda con frecuencia y ganancia', (
      tester,
    ) async {
      await _pump(tester, _FakeEqualizerService());

      expect(find.text('ECUALIZADOR'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.text('60 Hz'), findsOneWidget);
      expect(find.text('1 kHz'), findsOneWidget);
      expect(find.text('14 kHz'), findsOneWidget);
      expect(find.text('+3 dB'), findsOneWidget);
      expect(find.text('0 dB'), findsNWidgets(2));
      expect(find.text('Restablecer'), findsOneWidget);
    });

    testWidgets('el switch activa y desactiva los sliders', (tester) async {
      final service = _FakeEqualizerService();
      await _pump(tester, service);

      Slider firstSlider() => tester.widget<Slider>(find.byType(Slider).first);
      expect(firstSlider().onChanged, isNotNull);

      await tester.tap(find.text('Activar ecualizador'));
      await tester.pumpAndSettle();

      expect(service.enabled, isFalse);
      expect(firstSlider().onChanged, isNull);
    });

    testWidgets('avisa cuando un cambio no se pudo aplicar', (tester) async {
      final service = _FakeEqualizerService()..failWrites = true;
      await _pump(tester, service);

      await tester.tap(find.text('Activar ecualizador'));
      await tester.pump();

      expect(find.text('No se pudo aplicar el ecualizador'), findsOneWidget);
    });

    testWidgets('Restablecer deja las bandas en 0 dB', (tester) async {
      final service = _FakeEqualizerService();
      await _pump(tester, service);

      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();

      expect(find.text('+3 dB'), findsNothing);
      expect(find.text('0 dB'), findsNWidgets(3));
      expect(service.savedGains, [0, 0, 0]);
    });

    testWidgets('muestra aviso si el ecualizador no está disponible', (
      tester,
    ) async {
      final service = _FakeEqualizerService()..unavailable = true;
      await _pump(tester, service);

      expect(
        find.text('El ecualizador no está disponible en este dispositivo'),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsNothing);
    });
  });
}
