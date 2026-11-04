import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/equalizer/domain/models/equalizer_settings.dart';
import 'package:pulso/features/equalizer/domain/services/equalizer_service.dart';
import 'package:pulso/features/equalizer/presentation/controllers/equalizer_notifier.dart';
import 'package:pulso/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/settings/presentation/screens/settings_screen.dart';
import 'package:pulso/shared/base_data/audio/online_audio_cache.dart';
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
        // Las licencias quedan en el repositorio, no dentro de la app.
        expect(find.text('Licencias de código abierto'), findsNothing);
        expect(find.text('INFORMACIÓN'), findsNothing);
      },
    );

    testWidgets('muestra el tamaño de la caché en línea y permite vaciarla', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('pulso_settings_cache'),
      );
      addTearDown(() => tester.runAsync(() => root!.delete(recursive: true)));
      await tester.runAsync(
        () =>
            File('${root!.path}/a.audio')
                .writeAsBytes(List.filled(2 * 1024 * 1024, 0)),
      );
      final cache = OnlineAudioCache(directory: () async => root!);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [onlineAudioCacheProvider.overrideWithValue(cache)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await _pumpUntilFound(tester, find.text('2.0 MB guardados'));

      expect(find.text('Caché de música en línea'), findsOneWidget);
      expect(find.text('2.0 MB guardados'), findsOneWidget);

      // La entrada está al final de Ajustes: hay que desplazarse para tocarla.
      await tester.ensureVisible(find.text('Vaciar'));
      await tester.pump();
      await tester.tap(find.text('Vaciar'));
      await _pumpUntilFound(tester, find.text('Sin canciones guardadas'));

      expect(find.text('Sin canciones guardadas'), findsOneWidget);
      expect(await tester.runAsync(() => cache.sizeBytes()), 0);
    });

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

/// Las lecturas de disco reales se resuelven fuera del reloj simulado del
/// test: se deja correr el tiempo real y se redibuja hasta ver el resultado.
Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
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
