import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';

typedef ArtworkLoader = Future<Uint8List?> Function(
  int id,
  ArtworkType type,
  int size,
);

/// Resultado de una carátula ya resuelta, disponible de forma síncrona.
class ResolvedArtwork {
  final Uint8List? bytes;

  const ResolvedArtwork(this.bytes);
}

/// Caché LRU en memoria de carátulas de MediaStore.
///
/// Evita relanzar la consulta al canal de plataforma en cada rebuild o al
/// reciclar filas de una lista, y devuelve siempre la misma instancia de bytes
/// para que el `ImageCache` de Flutter no vuelva a decodificar la imagen.
class ArtworkCache {
  static const List<int> _buckets = [128, 256, 512, 1024];

  static final ArtworkCache instance = ArtworkCache();

  final ArtworkLoader _loader;
  final int maxEntries;
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();

  ArtworkCache({ArtworkLoader? loader, this.maxEntries = 300})
    : _loader = loader ?? _queryMediaStore;

  /// Redondea el tamaño físico solicitado al bucket superior, para que
  /// carátulas de tamaños parecidos compartan entrada.
  static int bucketFor(double logicalSize, double devicePixelRatio) {
    final physical = logicalSize * devicePixelRatio;
    for (final bucket in _buckets) {
      if (physical <= bucket) return bucket;
    }
    return _buckets.last;
  }

  /// Devuelve la carátula si ya fue resuelta, o `null` si aún no se cargó.
  ResolvedArtwork? peek(
    int id, {
    required ArtworkType type,
    required int size,
  }) {
    final entry = _entries[_key(id, type, size)];
    if (entry == null || !entry.isResolved) return null;
    return ResolvedArtwork(entry.bytes);
  }

  Future<Uint8List?> load(
    int id, {
    required ArtworkType type,
    required int size,
  }) {
    final key = _key(id, type, size);
    final cached = _entries.remove(key);
    if (cached != null) {
      // Reinsertar la marca como la más reciente.
      _entries[key] = cached;
      return cached.future;
    }

    final entry = _Entry();
    entry.future = _loader(id, type, size).then(
      (bytes) {
        entry
          ..bytes = bytes
          ..isResolved = true;
        return bytes;
      },
      onError: (Object _) {
        // No cachear fallos: se reintenta en la próxima solicitud.
        if (identical(_entries[key], entry)) _entries.remove(key);
        return null;
      },
    );

    _entries[key] = entry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return entry.future;
  }

  static String _key(int id, ArtworkType type, int size) =>
      '${type.index}:$id:$size';

  static Future<Uint8List?> _queryMediaStore(
    int id,
    ArtworkType type,
    int size,
  ) {
    return OnAudioQuery().queryArtwork(id, type, size: size);
  }
}

class _Entry {
  late final Future<Uint8List?> future;
  Uint8List? bytes;
  bool isResolved = false;
}
