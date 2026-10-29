import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/settings/presentation/screens/settings_screen.dart';

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
  });
}
