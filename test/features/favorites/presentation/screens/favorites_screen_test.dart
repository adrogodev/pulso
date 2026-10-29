import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pulso/features/library/presentation/controllers/library_notifier.dart';
import 'package:pulso/features/library/presentation/controllers/library_state.dart';

class MockFavLibraryNotifier extends LibraryNotifier {
  final LibraryState customState;
  MockFavLibraryNotifier(this.customState);

  @override
  LibraryState build() => customState;
}

class MockFavoritesNotifier extends FavoritesNotifier {
  final Set<String> customFavorites;
  MockFavoritesNotifier(this.customFavorites);

  @override
  Set<String> build() => customFavorites;
}

void main() {
  group('FavoritesScreen Widget', () {
    const sampleTrack = Track(
      id: 'fav-1',
      title: 'Pista Favorita',
      artist: 'Artista Destacado',
      album: 'Álbum',
      durationMs: 210000,
      uri: 'uri/fav',
    );

    testWidgets('muestra mensaje vacío cuando no hay favoritos', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesNotifierProvider.overrideWith(
              () => MockFavoritesNotifier({}),
            ),
            libraryNotifierProvider.overrideWith(
              () => MockFavLibraryNotifier(
                const LibraryState(tracks: [sampleTrack]),
              ),
            ),
          ],
          child: const MaterialApp(home: FavoritesScreen()),
        ),
      );

      expect(find.text('No tienes favoritos aún'), findsOneWidget);
      expect(find.text('Pista Favorita'), findsNothing);
    });

    testWidgets('muestra canciones favoritas cuando hay pistas guardadas', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesNotifierProvider.overrideWith(
              () => MockFavoritesNotifier({'fav-1'}),
            ),
            libraryNotifierProvider.overrideWith(
              () => MockFavLibraryNotifier(
                const LibraryState(tracks: [sampleTrack]),
              ),
            ),
          ],
          child: const MaterialApp(home: FavoritesScreen()),
        ),
      );

      expect(find.text('Pista Favorita'), findsOneWidget);
      expect(find.text('Artista Destacado'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}
