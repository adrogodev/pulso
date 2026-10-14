import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/entities/track/track.dart';
import 'package:pulso/features/library/presentation/providers/library_notifier.dart';
import 'package:pulso/features/library/presentation/providers/library_state.dart';
import 'package:pulso/features/search/presentation/screens/search_screen.dart';

class MockSearchLibraryNotifier extends LibraryNotifier {
  final LibraryState customState;
  MockSearchLibraryNotifier(this.customState);

  @override
  LibraryState build() => customState;
}

void main() {
  group('SearchScreen Widget', () {
    const track1 = Track(
      id: '1',
      title: 'Latido Nocturno',
      artist: 'Pulso',
      album: 'Frecuencia',
      durationMs: 180000,
      uri: 'uri/1',
    );

    testWidgets(
      'muestra estado inicial vacío y responde al escribir en el buscador',
      (tester) async {
        final libraryState = const LibraryState().copyWith(
          tracks: [track1],
          hasPermission: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              libraryNotifierProvider.overrideWith(
                () => MockSearchLibraryNotifier(libraryState),
              ),
            ],
            child: const MaterialApp(home: SearchScreen()),
          ),
        );

        expect(find.text('Explora tu música'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'nocturno');
        await tester.pumpAndSettle();

        expect(find.text('Latido Nocturno'), findsOneWidget);
      },
    );
  });
}
