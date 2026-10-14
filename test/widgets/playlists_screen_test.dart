import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/entities/playlist/playlist.dart';
import 'package:pulso/features/playlists/presentation/providers/playlists_notifier.dart';
import 'package:pulso/features/playlists/presentation/screens/playlists_screen.dart';

class MockPlaylistsNotifier extends PlaylistsNotifier {
  final List<Playlist> customPlaylists;
  MockPlaylistsNotifier(this.customPlaylists);

  @override
  List<Playlist> build() => customPlaylists;
}

void main() {
  group('PlaylistsScreen Widget', () {
    testWidgets('muestra estado vacío y botón para crear lista', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistsNotifierProvider.overrideWith(
              () => MockPlaylistsNotifier([]),
            ),
          ],
          child: const MaterialApp(home: PlaylistsScreen()),
        ),
      );

      expect(find.text('No tienes listas creadas'), findsOneWidget);
      expect(find.text('Crear primera lista'), findsOneWidget);
    });

    testWidgets('muestra listas existentes con su contador de canciones', (
      tester,
    ) async {
      final sampleList = Playlist(
        id: 'p-1',
        name: 'Música Nocturna',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        trackCount: 4,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistsNotifierProvider.overrideWith(
              () => MockPlaylistsNotifier([sampleList]),
            ),
          ],
          child: const MaterialApp(home: PlaylistsScreen()),
        ),
      );

      expect(find.text('Música Nocturna'), findsOneWidget);
      expect(find.text('4 canciones'), findsOneWidget);
    });
  });
}
