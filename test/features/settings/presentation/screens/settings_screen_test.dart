import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_settings.dart';
import 'package:pulso/features/equalizer/domain/services/equalizer_service.dart';
import 'package:pulso/features/equalizer/presentation/controllers/equalizer_notifier.dart';
import 'package:pulso/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:pulso/features/settings/presentation/screens/settings_screen.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

void main() {
  group('SettingsScreen Widget', () {
    testWidgets(
      'renderiza opciones de configuración y switches de preferencias',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: SettingsScreen())),
        );

        expect(find.text('CONFIGURACIÓN'), findsOneWidget);
        expect(find.text('Pulso'), findsOneWidget);
        expect(find.text('Actualizar biblioteca'), findsOneWidget);
        expect(find.text('Recordar última sesión'), findsOneWidget);
        expect(find.text('Ocultar notas de voz'), findsOneWidget);
        expect(find.text('Licencias de código abierto'), findsOneWidget);
      },
    );

    testWidgets('abre el ecualizador desde Ajustes', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            equalizerServiceProvider.overrideWithValue(
              _UnavailableEqualizerService(),
            ),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.tap(find.text('Ecualizador'));
      await tester.pumpAndSettle();

      expect(find.byType(EqualizerScreen), findsOneWidget);
    });
  });
}

/// Simula un dispositivo sin ecualizador, sin canales de plataforma.
class _UnavailableEqualizerService implements EqualizerService {
  static const _failure = Result<Never>.err(StorageFailure('No disponible'));

  @override
  Future<Result<EqualizerSettings>> load() async => _failure;

  @override
  Future<Result<void>> setEnabled(bool enabled) async => _failure;

  @override
  Future<Result<void>> setBandGain(int index, double gainDb) async => _failure;

  @override
  Future<Result<void>> saveGains(List<double> gainsDb) async => _failure;
}
