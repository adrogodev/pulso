import 'dart:async';
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

    test('sin copia completa, la pista suena directo desde la URL', () async {
      final source = await cache.audioSourceFor(_online, tag: 'x');

      expect(source, isA<UriAudioSource>());
      expect((source as UriAudioSource).uri.toString(), _online.uri);
    });

    test('con copia completa, la pista suena desde el archivo', () async {
      final file = await cache.fileFor(_online);
      await file.writeAsBytes([1, 2, 3]);

      final source = await cache.audioSourceFor(_online, tag: 'x');

      expect((source as UriAudioSource).uri, Uri.file(file.path));
    });

    test('una descarga a medias no se usa para reproducir', () async {
      final file = await cache.fileFor(_online);
      await file.writeAsBytes([1, 2, 3]);
      await File('${file.path}.part').writeAsBytes([4]);

      final source = await cache.audioSourceFor(_online, tag: 'x');

      expect((source as UriAudioSource).uri.toString(), _online.uri);
    });
  });

  group('OnlineAudioCache.saveInBackground', () {
    late List<(Uri, String)> downloads;
    late Completer<void> release;

    setUp(() {
      downloads = [];
      release = Completer<void>();
      cache = OnlineAudioCache(
        directory: () async => root,
        download: (uri, target) async {
          downloads.add((uri, target.path));
          await release.future;
          await target.writeAsBytes([1]);
        },
      );
    });

    test('descarga la pista en línea a su archivo de la caché', () async {
      final saving = cache.saveInBackground(_online);
      release.complete();
      await saving;

      expect(downloads.single.$1.toString(), _online.uri);
      expect(downloads.single.$2, (await cache.fileFor(_online)).path);
    });

    test('no repite una descarga en curso ni una ya guardada', () async {
      final first = cache.saveInBackground(_online);
      final second = cache.saveInBackground(_online);
      release.complete();
      await Future.wait([first, second]);
      await cache.saveInBackground(_online);

      expect(downloads, hasLength(1));
    });

    test('no descarga las pistas locales', () async {
      release.complete();
      await cache.saveInBackground(_local);

      expect(downloads, isEmpty);
    });
  });

  group('OnlineAudioCache.httpDownload', () {
    late ServerSocket server;

    /// Servidor HTTP mínimo que declara [declared] bytes, envía [body] y
    /// cierra la conexión, como un servidor que se corta a mitad de camino.
    Future<Uri> serve({required int declared, required List<int> body}) async {
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((socket) async {
        await socket.first;
        socket.add(
          'HTTP/1.1 200 OK\r\nContent-Type: audio/mp4\r\n'
                  'Content-Length: $declared\r\n\r\n'
              .codeUnits,
        );
        socket.add(body);
        await socket.flush();
        socket.destroy();
      });
      return Uri.parse('http://127.0.0.1:${server.port}/api/stream/x');
    }

    tearDown(() => server.close());

    test('guarda el archivo solo cuando llega completo', () async {
      final uri = await serve(declared: 4, body: [1, 2, 3, 4]);
      final target = File('${root.path}/x.audio');

      await OnlineAudioCache.httpDownload(uri, target);

      expect(await target.readAsBytes(), [1, 2, 3, 4]);
      expect(await File('${target.path}.part').exists(), isFalse);
    });

    test('descarta una descarga cortada antes de tiempo', () async {
      final uri = await serve(declared: 1000, body: [1, 2, 3]);
      final target = File('${root.path}/x.audio');

      await expectLater(
        OnlineAudioCache.httpDownload(uri, target),
        throwsA(isA<IOException>()),
      );
      expect(await target.exists(), isFalse);
      expect(await File('${target.path}.part').exists(), isFalse);
    });

    test('las pistas locales se reproducen directo, sin caché', () async {
      final source = await cache.audioSourceFor(_local, tag: 'x');

      expect(source, isA<UriAudioSource>());
      expect((source as UriAudioSource).uri.toString(), _local.uri);
    });
  });
}
