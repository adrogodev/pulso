import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/models/album.dart';
import 'package:pulso/shared/base_domain/models/artist.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/library/presentation/screens/album_detail_screen.dart';
import 'package:pulso/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/shared/ui_kit/widgets/track_info_dialog.dart';

class MockDetailFavoritesNotifier extends FavoritesNotifier {
  @override
  Set<String> build() => {};
}

class MockDetailPlaybackNotifier extends PlaybackNotifier {
  @override
  PlaybackState build() => const PlaybackState();
}

void main() {
  const sampleTrack = Track(
    id: 'track-10',
    title: 'Pista de Prueba',
    artist: 'Artista Destacado',
    album: 'Álbum Increíble',
    durationMs: 240000,
    uri: '/sdcard/Music/test.mp3',
    trackNumber: 3,
    year: 2024,
    size: 5242880,
    fileExtension: 'mp3',
  );

  const sampleAlbum = Album(
    id: 1,
    title: 'Álbum Increíble',
    artist: 'Artista Destacado',
    numOfSongs: 1,
    firstYear: 2024,
  );

  const sampleArtist = Artist(
    id: 1,
    name: 'Artista Destacado',
    numOfTracks: 1,
    numOfAlbums: 1,
  );

  group('AlbumDetailScreen Widget', () {
    testWidgets('renderiza detalles del álbum, pistas y botones de acción', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesNotifierProvider.overrideWith(
              () => MockDetailFavoritesNotifier(),
            ),
            playbackNotifierProvider.overrideWith(
              () => MockDetailPlaybackNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: AlbumDetailScreen(
              album: sampleAlbum,
              initialTracks: [sampleTrack],
            ),
          ),
        ),
      );

      expect(find.text('Álbum Increíble'), findsWidgets);
      expect(find.text('Artista Destacado'), findsWidgets);
      expect(find.text('Reproducir'), findsOneWidget);
      expect(find.text('Aleatorio'), findsOneWidget);
      expect(find.text('Pista de Prueba'), findsOneWidget);
    });
  });

  group('ArtistDetailScreen Widget', () {
    testWidgets('renderiza detalles del artista y pistas asociadas', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesNotifierProvider.overrideWith(
              () => MockDetailFavoritesNotifier(),
            ),
            playbackNotifierProvider.overrideWith(
              () => MockDetailPlaybackNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ArtistDetailScreen(
              artist: sampleArtist,
              initialTracks: [sampleTrack],
            ),
          ),
        ),
      );

      expect(find.text('Artista Destacado'), findsWidgets);
      expect(find.text('1 álbum • 1 canción'), findsOneWidget);
      expect(find.text('Pista de Prueba'), findsOneWidget);
    });
  });

  group('TrackInfoDialog Widget', () {
    testWidgets('muestra metadatos técnicos y URI del archivo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TrackInfoDialog(track: sampleTrack)),
        ),
      );

      expect(find.text('Información del archivo'), findsOneWidget);
      expect(find.text('Pista de Prueba'), findsOneWidget);
      expect(find.text('Artista Destacado'), findsOneWidget);
      expect(find.text('Álbum Increíble'), findsOneWidget);
      expect(find.text('MP3'), findsOneWidget);
      expect(find.text('5.0 MB'), findsOneWidget);
      expect(find.text('/sdcard/Music/test.mp3'), findsOneWidget);
    });
  });
}
