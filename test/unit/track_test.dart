import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/entities/track/track.dart';

void main() {
  group('Track Entity', () {
    const sampleTrack = Track(
      id: '101',
      title: 'Resonancia',
      artist: 'Pulso Project',
      album: 'Frecuencias',
      durationMs: 215000, // 3 min 35 seg
      uri: '/storage/emulated/0/Music/resonancia.mp3',
      fileExtension: 'mp3',
    );

    test(
      'calcula y formatea la duración correctamente en minutos y segundos',
      () {
        expect(sampleTrack.formattedDuration, '03:35');
        expect(sampleTrack.duration.inSeconds, 215);
      },
    );

    test('formatea duraciones largas con horas adecuadamente', () {
      final longTrack = sampleTrack.copyWith(
        durationMs: 3665000, // 1 hora, 1 minuto, 5 segundos
      );
      expect(longTrack.formattedDuration, '1:01:05');
    });

    test('valida formatos de audio admitidos', () {
      expect(sampleTrack.isSupportedFormat, isTrue);

      final flacTrack = sampleTrack.copyWith(fileExtension: 'flac');
      expect(flacTrack.isSupportedFormat, isTrue);

      final wavTrack = sampleTrack.copyWith(fileExtension: 'wav');
      expect(wavTrack.isSupportedFormat, isTrue);

      final oggTrack = sampleTrack.copyWith(fileExtension: 'ogg');
      expect(oggTrack.isSupportedFormat, isTrue);

      final unsupportedTrack = sampleTrack.copyWith(fileExtension: 'pdf');
      expect(unsupportedTrack.isSupportedFormat, isFalse);
    });

    test('soporta inmutabilidad y comparaciones de igualdad', () {
      const cloneTrack = Track(
        id: '101',
        title: 'Resonancia',
        artist: 'Pulso Project',
        album: 'Frecuencias',
        durationMs: 215000,
        uri: '/storage/emulated/0/Music/resonancia.mp3',
      );

      expect(sampleTrack == cloneTrack, isTrue);
      expect(sampleTrack.hashCode == cloneTrack.hashCode, isTrue);
    });
  });
}
