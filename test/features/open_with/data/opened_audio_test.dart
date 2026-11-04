import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/open_with/data/data_sources/opened_audio_channel.dart';
import 'package:pulso/features/open_with/data/mappers/opened_audio_mapper.dart';
import 'package:pulso/features/open_with/domain/models/opened_audio.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('trackFromOpenedAudio', () {
    test('usa el nombre del archivo, sin extensión, como título', () {
      final track = trackFromOpenedAudio(
        const OpenedAudio(
          uri: 'content://com.whatsapp.provider/audio/1',
          displayName: 'Nota de voz.opus',
        ),
      );

      expect(track.id, 'external:content://com.whatsapp.provider/audio/1');
      expect(track.title, 'Nota de voz');
      expect(track.fileExtension, 'opus');
      expect(track.artist, Track.unknownArtist);
      expect(track.album, 'Audio externo');
      expect(track.uri, 'content://com.whatsapp.provider/audio/1');
      expect(track.isRemote, isFalse);
    });

    test('sin nombre, toma el último tramo de la ruta', () {
      final track = trackFromOpenedAudio(
        const OpenedAudio(uri: 'file:///sdcard/Download/mi%20cancion.mp3'),
      );

      expect(track.title, 'mi cancion');
      expect(track.fileExtension, 'mp3');
    });

    test('si no hay de dónde sacar un nombre, lo llama "Audio"', () {
      final track = trackFromOpenedAudio(
        const OpenedAudio(uri: 'content://media/'),
      );

      expect(track.title, 'Audio');
      expect(track.fileExtension, isNull);
    });
  });

  group('OpenedAudioChannel', () {
    const method = MethodChannel(OpenedAudioChannel.name);
    late List<String> calls;

    void answer(Object? audio) {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(method, (call) async {
            calls.add(call.method);
            return audio;
          });
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(method, null);
    });

    test('toma el audio que Android le pasó a la app', () async {
      answer({'uri': 'content://a/1', 'displayName': 'canción.m4a'});

      final audio = await OpenedAudioChannel().take();

      expect(calls, ['takeOpenedAudio']);
      expect(audio?.uri, 'content://a/1');
      expect(audio?.displayName, 'canción.m4a');
    });

    test('devuelve null cuando no hay audio pendiente', () async {
      answer(null);

      expect(await OpenedAudioChannel().take(), isNull);
    });

    test('avisa cuando llega un audio con la app abierta', () async {
      var notified = 0;
      OpenedAudioChannel().onAvailable(() => notified++);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            OpenedAudioChannel.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('audioAvailable'),
            ),
            (_) {},
          );

      expect(notified, 1);
    });
  });
}
