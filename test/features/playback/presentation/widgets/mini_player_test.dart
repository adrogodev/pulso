import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/playback/presentation/widgets/mini_player.dart';

class TestPlaybackNotifier extends PlaybackNotifier {
  final PlaybackState initialState;
  TestPlaybackNotifier(this.initialState);

  @override
  PlaybackState build() => initialState;
}

void main() {
  group('MiniPlayer Widget', () {
    testWidgets('desaparece cuando no hay pista seleccionada', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: MiniPlayer())),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Título'), findsNothing);
    });

    testWidgets('muestra título y artista cuando hay pista activa', (
      tester,
    ) async {
      const activeTrack = Track(
        id: '1',
        title: 'Pulso Inicial',
        artist: 'Artista Maestro',
        album: 'Álbum Uno',
        durationMs: 200000,
        uri: 'uri/test',
      );

      final state = const PlaybackState().copyWith(
        currentTrack: activeTrack,
        queue: [activeTrack],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackNotifierProvider.overrideWith(
              () => TestPlaybackNotifier(state),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
        ),
      );

      expect(find.text('Pulso Inicial'), findsOneWidget);
      expect(find.text('Artista Maestro'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
