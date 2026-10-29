import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_data/audio/audio_player_service.dart';
import 'package:pulso/shared/base_domain/models/album.dart';
import 'package:pulso/shared/base_domain/models/artist.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/library/presentation/controllers/library_notifier.dart';
import 'package:pulso/features/library/presentation/controllers/library_state.dart';
import 'package:pulso/app/presentation/screens/home_screen.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';

class MockHomeLibraryNotifier extends LibraryNotifier {
  final LibraryState customState;
  MockHomeLibraryNotifier(this.customState);

  @override
  LibraryState build() => customState;

  @override
  Future<void> checkPermissionsAndLoad() async {}
}

class MockHomeFavoritesNotifier extends FavoritesNotifier {
  final Set<String> customFavorites;
  MockHomeFavoritesNotifier([this.customFavorites = const {}]);

  @override
  Set<String> build() => customFavorites;
}

class MockHomePlaybackNotifier extends PlaybackNotifier {
  final PlaybackState customState;
  MockHomePlaybackNotifier([this.customState = const PlaybackState()]);

  @override
  PlaybackState build() => customState;
}

void main() {
  group('HomeScreen Widget', () {
    const sampleTrack = Track(
      id: '1',
      title: 'Canción Principal',
      artist: 'Artista Principal',
      album: 'Álbum Uno',
      durationMs: 180000,
      uri: 'uri/1.mp3',
    );

    const sampleAlbum = Album(
      id: 1,
      title: 'Álbum Uno',
      artist: 'Artista Principal',
      numOfSongs: 1,
    );

    const sampleArtist = Artist(
      id: 1,
      name: 'Artista Principal',
      numOfTracks: 1,
      numOfAlbums: 1,
    );

    testWidgets('renderiza cabecera con Pulso, acciones y pestañas', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith(
              () => MockHomeLibraryNotifier(const LibraryState()),
            ),
            favoritesNotifierProvider.overrideWith(
              () => MockHomeFavoritesNotifier(),
            ),
            playbackNotifierProvider.overrideWith(
              () => MockHomePlaybackNotifier(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('Pulso'), findsOneWidget);
      expect(find.text('Canciones'), findsOneWidget);
      expect(find.text('Álbumes'), findsOneWidget);
      expect(find.text('Artistas'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byTooltip('Buscar en línea'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay canciones', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith(
              () => MockHomeLibraryNotifier(const LibraryState(tracks: [])),
            ),
            favoritesNotifierProvider.overrideWith(
              () => MockHomeFavoritesNotifier(),
            ),
            playbackNotifierProvider.overrideWith(
              () => MockHomePlaybackNotifier(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('No se encontraron canciones'), findsOneWidget);
      expect(find.text('Escanear biblioteca'), findsOneWidget);
    });

    testWidgets('muestra lista de canciones cuando hay pistas cargadas', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith(
              () => MockHomeLibraryNotifier(
                const LibraryState(
                  tracks: [sampleTrack],
                  albums: [sampleAlbum],
                  artists: [sampleArtist],
                ),
              ),
            ),
            favoritesNotifierProvider.overrideWith(
              () => MockHomeFavoritesNotifier(),
            ),
            playbackNotifierProvider.overrideWith(
              () => MockHomePlaybackNotifier(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('Canción Principal'), findsOneWidget);
      expect(find.text('1 canción • 1 álbum'), findsOneWidget);
    });

    testWidgets(
      'muestra mini reproductor acoplado cuando hay una pista activa',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              libraryNotifierProvider.overrideWith(
                () => MockHomeLibraryNotifier(
                  const LibraryState(tracks: [sampleTrack]),
                ),
              ),
              favoritesNotifierProvider.overrideWith(
                () => MockHomeFavoritesNotifier(),
              ),
              playbackNotifierProvider.overrideWith(
                () => MockHomePlaybackNotifier(
                  const PlaybackState(
                    currentTrack: sampleTrack,
                    queue: [sampleTrack],
                    status: AppPlayerStatus.playing,
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Canción Principal'), findsWidgets);
      },
    );
  });
}
