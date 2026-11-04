import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/playback/presentation/screens/expanded_player_screen.dart';
import 'package:pulso/features/playlists/presentation/controllers/playlists_notifier.dart';
import 'package:pulso/features/queue/presentation/screens/queue_screen.dart';
import 'package:pulso/shared/base_domain/models/playlist.dart';
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

/// Listas en memoria, sin base de datos.
class _TestPlaylistsNotifier extends PlaylistsNotifier {
  @override
  List<Playlist> build() => [
    Playlist(
      id: 'p1',
      name: 'Para correr',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  final List<(String, String)> added = [];

  @override
  Future<void> addTrack(String playlistId, String trackId) async {
    added.add((playlistId, trackId));
  }
}

Widget _app({Track track = _track, _TestPlaylistsNotifier? playlists}) =>
    ProviderScope(
      overrides: [
        playbackNotifierProvider.overrideWith(
          () => _TestPlaybackNotifier(
            const PlaybackState().copyWith(currentTrack: track, queue: [track]),
          ),
        ),
        favoritesNotifierProvider.overrideWith(_TestFavoritesNotifier.new),
        playlistsNotifierProvider.overrideWith(
          () => playlists ?? _TestPlaylistsNotifier(),
        ),
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

    testWidgets('agrega la canción que suena a una lista', (tester) async {
      final playlists = _TestPlaylistsNotifier();
      await tester.pumpWidget(_app(playlists: playlists));

      await tester.tap(find.byTooltip('Añadir a una lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Para correr'));
      await tester.pumpAndSettle();

      expect(playlists.added, [('p1', '7')]);
      expect(find.text('Añadida a "Para correr"'), findsOneWidget);
    });

    testWidgets(
      'no ofrece listas para canciones fuera de la biblioteca local',
      (tester) async {
        // Las listas guardan ids de la biblioteca: una canción en línea no
        // se podría volver a encontrar.
        await tester.pumpWidget(
          _app(
            track: const Track(
              id: 'rythmx:abc',
              title: 'En línea',
              artist: 'A',
              album: 'YouTube Music',
              durationMs: 1000,
              uri: 'https://api.ejemplo.com/api/stream/abc',
            ),
          ),
        );

        expect(find.byTooltip('Añadir a una lista'), findsNothing);
      },
    );
  });
}
