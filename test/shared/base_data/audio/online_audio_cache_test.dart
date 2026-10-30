// LockCachingAudioSource es experimental en just_audio 0.10; el test fija
// que la caché lo use, así un cambio de su API se detecta aquí.
// ignore_for_file: experimental_member_use

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pulso/shared/base_data/audio/online_audio_cache.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

const _online = Track(
  id: 'audius:abc',
  title: 'Lluvia',
  artist: 'Artista',
  album: 'Audius',
  durationMs: 1000,
  uri: 'https://api.audius.co/v1/tracks/abc/stream?app_name=pulso',
);

const _local = Track(
  id: '42',
  title: 'Local',
  artist: 'Artista',
  album: 'Álbum',
  durationMs: 1000,
  uri: 'content://media/external/audio/media/42',
);

void main() {
  late Directory root;
  late OnlineAudioCache cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pulso_cache_test');
    cache = OnlineAudioCache(directory: () async => root, maxBytes: 100);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<File> write(String name, int bytes, {required int ageMinutes}) async {
    final file = File('${root.path}/$name');
    await file.writeAsBytes(List.filled(bytes, 0));
    await file.setLastModified(
      DateTime.now().subtract(Duration(minutes: ageMinutes)),
    );
    return file;
  }

  group('OnlineAudioCache', () {
    test('asigna a cada pista un archivo estable dentro de la caché', () async {
      final first = await cache.fileFor(_online);
      final second = await cache.fileFor(_online);

      expect(first.path, second.path);
      expect(first.parent.path, root.path);
      expect(first.path, endsWith('audius_abc.audio'));
    });

    test('suma el tamaño de todo lo guardado', () async {
      await write('a.audio', 30, ageMinutes: 1);
      await write('b.audio.part', 20, ageMinutes: 1);

      expect(await cache.sizeBytes(), 50);
    });

    test('al superar el límite borra primero lo más antiguo', () async {
      final oldest = await write('viejo.audio', 60, ageMinutes: 30);
      final middle = await write('medio.audio', 30, ageMinutes: 20);
      final newest = await write('nuevo.audio', 30, ageMinutes: 1);

      await cache.trim();

      expect(await oldest.exists(), isFalse);
      expect(await middle.exists(), isTrue);
      expect(await newest.exists(), isTrue);
      expect(await cache.sizeBytes(), lessThanOrEqualTo(100));
    });

    test('vaciar la caché borra todo', () async {
      await write('a.audio', 10, ageMinutes: 1);

      await cache.clear();

      expect(await cache.sizeBytes(), 0);
    });

    test('las pistas en línea se reproducen desde la caché', () async {
      final source = await cache.audioSourceFor(_online, tag: 'x');

      expect(source, isA<LockCachingAudioSource>());
      final file = await (source as LockCachingAudioSource).cacheFile;
      expect(file.path, (await cache.fileFor(_online)).path);
    });

    test('las pistas locales se reproducen directo, sin caché', () async {
      final source = await cache.audioSourceFor(_local, tag: 'x');

      expect(source, isA<UriAudioSource>());
      expect((source as UriAudioSource).uri.toString(), _local.uri);
    });
  });
}
