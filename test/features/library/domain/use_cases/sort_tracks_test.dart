import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/library/domain/use_cases/sort_tracks_usecase.dart';

void main() {
  group('SortTracksUseCase', () {
    const useCase = SortTracksUseCase();

    const trackA = Track(
      id: '1',
      title: 'Alfa',
      artist: 'Zeta',
      album: 'Luna',
      durationMs: 300000,
      uri: 'uri/1',
    );
    const trackB = Track(
      id: '2',
      title: 'Beta',
      artist: 'Alfa',
      album: 'Sol',
      durationMs: 150000,
      uri: 'uri/2',
    );
    const trackC = Track(
      id: '3',
      title: 'Gamma',
      artist: 'Beta',
      album: 'Astro',
      durationMs: 200000,
      uri: 'uri/3',
    );

    final list = [trackC, trackA, trackB];

    test('ordena por título de forma ascendente y descendente', () {
      final asc = useCase(list, criteria: TrackSortCriteria.title);
      expect(asc.map((t) => t.title), ['Alfa', 'Beta', 'Gamma']);

      final desc = useCase(
        list,
        criteria: TrackSortCriteria.title,
        order: SortOrder.descending,
      );
      expect(desc.map((t) => t.title), ['Gamma', 'Beta', 'Alfa']);
    });

    test('ordena por artista', () {
      final asc = useCase(list, criteria: TrackSortCriteria.artist);
      expect(asc.map((t) => t.artist), ['Alfa', 'Beta', 'Zeta']);
    });

    test('ordena por álbum', () {
      final asc = useCase(list, criteria: TrackSortCriteria.album);
      expect(asc.map((t) => t.album), ['Astro', 'Luna', 'Sol']);
    });

    test('ordena por duración', () {
      final asc = useCase(list, criteria: TrackSortCriteria.duration);
      expect(asc.map((t) => t.durationMs), [150000, 200000, 300000]);
    });
  });
}
