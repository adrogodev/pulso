import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/library/domain/use_cases/filter_music_usecase.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

Track _track(String id, {required int seconds, String? artist}) => Track(
  id: id,
  title: 'Pista $id',
  artist: artist ?? Track.unknownArtist,
  album: 'Álbum',
  durationMs: seconds * 1000,
  uri: 'uri/$id',
);

void main() {
  group('FilterMusicUseCase', () {
    const useCase = FilterMusicUseCase();

    final voiceNote = _track('nota', seconds: 12);
    final shortSong = _track('corta', seconds: 45, artist: 'Jaime Murrell');
    final longUnknown = _track('larga', seconds: 240);
    final edge = _track('borde', seconds: 60);

    final library = [voiceNote, shortSong, longUnknown, edge];

    test('oculta audios cortos sin artista conocido', () {
      final result = useCase(library, hideShortClips: true);

      expect(result, isNot(contains(voiceNote)));
    });

    test('conserva las canciones cortas con artista conocido', () {
      final result = useCase(library, hideShortClips: true);

      expect(result, contains(shortSong));
    });

    test('conserva los audios largos aunque no tengan artista', () {
      final result = useCase(library, hideShortClips: true);

      expect(result, containsAll([longUnknown, edge]));
    });

    test('no filtra nada cuando la preferencia está desactivada', () {
      expect(useCase(library, hideShortClips: false), library);
    });
  });
}
