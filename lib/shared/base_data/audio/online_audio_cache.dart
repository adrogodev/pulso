import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../base_domain/models/track.dart';

/// Caché en disco de la música en línea, dentro del directorio de caché de la
/// app (no en la biblioteca del teléfono).
///
/// Mientras una pista en línea suena se guarda completa; las siguientes veces
/// se reproduce desde el archivo, sin red: arranca al instante y no se corta
/// con una conexión inestable. Android puede vaciar este directorio si le
/// falta espacio, y [trim] lo mantiene por debajo de [maxBytes].
class OnlineAudioCache {
  static const int defaultMaxBytes = 500 * 1024 * 1024;

  /// Resuelve el directorio de la caché; se llama de forma diferida porque
  /// obtener el directorio de caché de la app es asíncrono.
  final Future<Directory> Function() directory;
  final int maxBytes;

  OnlineAudioCache({required this.directory, this.maxBytes = defaultMaxBytes});

  Future<Directory> get _root async {
    final dir = await directory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Archivo donde se guarda la pista; el nombre se deriva de su id.
  Future<File> fileFor(Track track) async {
    final name = track.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${(await _root).path}${Platform.pathSeparator}$name.audio');
  }

  /// Fuente de audio para la pista: en línea con caché, local sin ella.
  Future<AudioSource> audioSourceFor(Track track, {Object? tag}) async {
    if (track.isRemote) {
      // Experimental en just_audio 0.10, pero es la vía oficial para guardar
      // el streaming mientras suena; su uso está fijado por un test.
      // ignore: experimental_member_use
      return LockCachingAudioSource(
        Uri.parse(track.uri),
        cacheFile: await fileFor(track),
        tag: tag,
      );
    }
    final uri =
        track.uri.startsWith('content://') || track.uri.startsWith('file://')
        ? Uri.parse(track.uri)
        : Uri.file(track.uri);
    return AudioSource.uri(uri, tag: tag);
  }

  /// Espacio ocupado, incluidas las descargas a medias (.part).
  Future<int> sizeBytes() async {
    var total = 0;
    for (final file in await _files()) {
      total += await file.length();
    }
    return total;
  }

  /// Borra lo más antiguo hasta quedar por debajo de [maxBytes].
  Future<void> trim() async {
    final files = await _files();
    final entries = [
      for (final file in files)
        (file: file, size: await file.length(), at: await file.lastModified()),
    ]..sort((a, b) => a.at.compareTo(b.at));

    var total = entries.fold<int>(0, (sum, e) => sum + e.size);
    for (final entry in entries) {
      if (total <= maxBytes) break;
      try {
        await entry.file.delete();
        total -= entry.size;
      } on FileSystemException {
        // En uso por la reproducción actual: se conserva.
      }
    }
  }

  /// Vacía la caché por completo.
  Future<void> clear() async {
    for (final file in await _files()) {
      try {
        await file.delete();
      } on FileSystemException {
        // En uso por la reproducción actual: se conserva.
      }
    }
  }

  Future<List<File>> _files() async {
    final dir = await _root;
    return [
      await for (final e in dir.list())
        if (e is File) e,
    ];
  }
}
