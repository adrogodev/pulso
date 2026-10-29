import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:pulso/shared/base_data/artwork/artwork_cache.dart';

void main() {
  group('ArtworkCache', () {
    late int calls;
    late ArtworkCache cache;

    setUp(() {
      calls = 0;
      cache = ArtworkCache(
        maxEntries: 2,
        loader: (id, type, size) async {
          calls++;
          return Uint8List.fromList([id, size ~/ 128]);
        },
      );
    });

    test('reutiliza la misma consulta para la misma carátula', () async {
      final first = cache.load(1, type: ArtworkType.AUDIO, size: 128);
      final second = cache.load(1, type: ArtworkType.AUDIO, size: 128);

      expect(identical(first, second), isTrue);
      expect(identical(await first, await second), isTrue);
      expect(calls, 1);
    });

    test('expone de forma síncrona las carátulas ya resueltas', () async {
      expect(cache.peek(1, type: ArtworkType.AUDIO, size: 128), isNull);

      final bytes = await cache.load(1, type: ArtworkType.AUDIO, size: 128);

      final entry = cache.peek(1, type: ArtworkType.AUDIO, size: 128);
      expect(entry, isNotNull);
      expect(identical(entry!.bytes, bytes), isTrue);
    });

    test('desaloja la entrada menos usada al superar el límite', () async {
      await cache.load(1, type: ArtworkType.AUDIO, size: 128);
      await cache.load(2, type: ArtworkType.AUDIO, size: 128);
      // Tocar la 1 la vuelve la más reciente; la 2 pasa a ser la más antigua.
      await cache.load(1, type: ArtworkType.AUDIO, size: 128);
      await cache.load(3, type: ArtworkType.AUDIO, size: 128);

      expect(calls, 3);
      expect(cache.peek(2, type: ArtworkType.AUDIO, size: 128), isNull);
      expect(cache.peek(1, type: ArtworkType.AUDIO, size: 128), isNotNull);
    });

    test('peek marca la entrada como usada recientemente', () async {
      await cache.load(1, type: ArtworkType.AUDIO, size: 128);
      await cache.load(2, type: ArtworkType.AUDIO, size: 128);
      // La 1 se está mostrando: no debe desalojarse antes que la 2.
      cache.peek(1, type: ArtworkType.AUDIO, size: 128);
      await cache.load(3, type: ArtworkType.AUDIO, size: 128);

      expect(cache.peek(1, type: ArtworkType.AUDIO, size: 128), isNotNull);
      expect(cache.peek(2, type: ArtworkType.AUDIO, size: 128), isNull);
    });

    test('no guarda errores y permite reintentar', () async {
      var fail = true;
      final flaky = ArtworkCache(
        loader: (id, type, size) async {
          calls++;
          if (fail) throw Exception('MediaStore no disponible');
          return Uint8List(1);
        },
      );

      expect(await flaky.load(1, type: ArtworkType.AUDIO, size: 128), isNull);
      fail = false;
      expect(
        await flaky.load(1, type: ArtworkType.AUDIO, size: 128),
        isNotNull,
      );
      expect(calls, 2);
    });

    test('agrupa tamaños físicos en buckets para compartir entradas', () {
      expect(ArtworkCache.bucketFor(48, 2.0), 128);
      expect(ArtworkCache.bucketFor(48, 3.0), 256);
      expect(ArtworkCache.bucketFor(340, 3.0), 1024);
      expect(ArtworkCache.bucketFor(2000, 3.0), 1024);
    });
  });
}
