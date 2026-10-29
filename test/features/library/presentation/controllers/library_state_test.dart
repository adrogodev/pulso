import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/library/domain/use_cases/sort_tracks_usecase.dart';
import 'package:pulso/features/library/presentation/controllers/library_state.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

void main() {
  group('LibraryState', () {
    const tracks = [
      Track(
        id: '2',
        title: 'Beta',
        artist: 'A',
        album: 'X',
        durationMs: 1000,
        uri: 'uri/2',
      ),
      Track(
        id: '1',
        title: 'Alfa',
        artist: 'B',
        album: 'Y',
        durationMs: 2000,
        uri: 'uri/1',
      ),
    ];

    test('memoiza sortedTracks para no reordenar en cada lectura', () {
      const state = LibraryState(tracks: tracks);

      final first = state.sortedTracks;
      final second = state.sortedTracks;

      expect(identical(first, second), isTrue);
      expect(first.map((t) => t.title), ['Alfa', 'Beta']);
    });

    test('sortedTracks no se puede modificar desde fuera', () {
      const state = LibraryState(tracks: tracks);

      expect(() => state.sortedTracks.removeLast(), throwsUnsupportedError);
      expect(state.sortedTracks, hasLength(2));
    });

    test('recalcula sortedTracks cuando cambia la ordenación', () {
      const state = LibraryState(tracks: tracks);
      final ascending = state.sortedTracks;

      final descending = state
          .copyWith(sortOrder: SortOrder.descending)
          .sortedTracks;

      expect(identical(ascending, descending), isFalse);
      expect(descending.map((t) => t.title), ['Beta', 'Alfa']);
    });
  });
}
