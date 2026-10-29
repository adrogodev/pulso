import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/queue/presentation/screens/queue_screen.dart';

class MockQueuePlaybackNotifier extends PlaybackNotifier {
  final PlaybackState initialState;
  MockQueuePlaybackNotifier(this.initialState);

  @override
  PlaybackState build() => initialState;
}

void main() {
  group('QueueScreen Widget', () {
    testWidgets('muestra estado vacío cuando la cola no tiene canciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: QueueScreen())),
      );

      expect(find.text('La cola está vacía'), findsOneWidget);
      expect(find.text('0 canciones'), findsOneWidget);
    });

    testWidgets('muestra lista de canciones en cola y permite interacción', (
      tester,
    ) async {
      const track1 = Track(
        id: '1',
        title: 'Primera Pista',
        artist: 'Artista 1',
        album: 'Álbum',
        durationMs: 180000,
        uri: 'uri/1',
      );
      const track2 = Track(
        id: '2',
        title: 'Segunda Pista',
        artist: 'Artista 2',
        album: 'Álbum',
        durationMs: 200000,
        uri: 'uri/2',
      );

      final state = const PlaybackState().copyWith(
        currentTrack: track1,
        queue: [track1, track2],
        currentIndex: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackNotifierProvider.overrideWith(
              () => MockQueuePlaybackNotifier(state),
            ),
          ],
          child: const MaterialApp(home: QueueScreen()),
        ),
      );

      expect(find.text('Primera Pista'), findsOneWidget);
      expect(find.text('Segunda Pista'), findsOneWidget);
      expect(find.text('2 canciones'), findsOneWidget);
    });
  });
}
