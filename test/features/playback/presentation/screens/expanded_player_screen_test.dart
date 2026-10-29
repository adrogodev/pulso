import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/playback/presentation/screens/expanded_player_screen.dart';
import 'package:pulso/features/queue/presentation/screens/queue_screen.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

class _TestPlaybackNotifier extends PlaybackNotifier {
  _TestPlaybackNotifier(this.initialState);

  final PlaybackState initialState;

  @override
  PlaybackState build() => initialState;
}

/// Favoritos en memoria, sin base de datos.
class _TestFavoritesNotifier extends FavoritesNotifier {
  @override
  Set<String> build() => const {};

  @override
  Future<void> toggleFavorite(String trackId) async {
    state = state.contains(trackId)
        ? ({...state}..remove(trackId))
        : {...state, trackId};
  }
}

const _track = Track(
  id: '7',
  title: 'Boreal',
  artist: 'Pulso',
  album: 'Norte',
  durationMs: 200000,
  uri: 'uri/7',
);

Widget _app() => ProviderScope(
  overrides: [
    playbackNotifierProvider.overrideWith(
      () => _TestPlaybackNotifier(
        const PlaybackState().copyWith(currentTrack: _track, queue: [_track]),
      ),
    ),
    favoritesNotifierProvider.overrideWith(_TestFavoritesNotifier.new),
  ],
  child: const MaterialApp(home: ExpandedPlayerScreen()),
);

void main() {
  group('ExpandedPlayerScreen Widget', () {
    testWidgets('marca y desmarca la pista actual como favorita', (
      tester,
    ) async {
      await tester.pumpWidget(_app());

      expect(find.byTooltip('Añadir a favoritos'), findsOneWidget);

      await tester.tap(find.byTooltip('Añadir a favoritos'));
      await tester.pump();
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pump();
      expect(find.byTooltip('Añadir a favoritos'), findsOneWidget);
    });

    testWidgets('abre la cola de reproducción', (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.byTooltip('Cola de reproducción'));
      await tester.pumpAndSettle();

      expect(find.byType(QueueScreen), findsOneWidget);
    });
  });
}
