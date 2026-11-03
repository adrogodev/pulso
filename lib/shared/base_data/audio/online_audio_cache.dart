import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../base_domain/models/track.dart';

/// Descarga [uri] completa en [target]; se inyecta en los tests.
typedef AudioDownload = Future<void> Function(Uri uri, File target);

/// Caché en disco de la música en línea, dentro del directorio de caché de la
/// app (no en la biblioteca del teléfono).
///
/// Una pista en línea suena directo desde su URL, tal cual la entrega el
/// servidor, y a la vez se descarga aparte con [saveInBackground]; las
/// siguientes veces se reproduce desde el archivo, sin red. Solo se usa una
/// copia completa: si la descarga se corta, se descarta. Android puede vaciar
/// este directorio si le falta espacio, y [trim] lo mantiene por debajo de
/// [maxBytes].
class OnlineAudioCache {
  static const int defaultMaxBytes = 500 * 1024 * 1024;

  /// Resuelve el directorio de la caché; se llama de forma diferida porque
  /// obtener el directorio de caché de la app es asíncrono.
  final Future<Directory> Function() directory;
  final int maxBytes;
  final AudioDownload _download;

  /// Descargas en curso, por id de pista, para no repetirlas.
  final Set<String> _saving = {};

  OnlineAudioCache({
    required this.directory,
    this.maxBytes = defaultMaxBytes,
    AudioDownload? download,
  }) : _download = download ?? httpDownload;

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

  /// Fuente de audio para la pista: la copia completa guardada si existe; si
  /// no, la URL en línea. Las pistas locales se reproducen directo.
  ///
  /// No se usa el proxy de LockCachingAudioSource: mientras descargaba podía
  /// cerrar el audio antes de tiempo y la canción saltaba a la siguiente.
  Future<AudioSource> audioSourceFor(Track track, {Object? tag}) async {
    if (track.isRemote) {
      final file = await fileFor(track);
      return await _isComplete(file)
          ? AudioSource.uri(Uri.file(file.path), tag: tag)
          : AudioSource.uri(Uri.parse(track.uri), tag: tag);
    }
    final uri =
        track.uri.startsWith('content://') || track.uri.startsWith('file://')
        ? Uri.parse(track.uri)
        : Uri.file(track.uri);
    return AudioSource.uri(uri, tag: tag);
  }

  /// Guarda en la caché la pista en línea que empieza a sonar. No hace nada
  /// si ya está guardada o descargándose; un fallo solo se registra, porque la
  /// reproducción no depende de la caché.
  Future<void> saveInBackground(Track track) async {
    // Se marca antes de cualquier espera para que dos llamadas seguidas no
    // descarguen la misma pista.
    if (!track.isRemote || !_saving.add(track.id)) return;
    try {
      final file = await fileFor(track);
      if (await _isComplete(file)) return;
      await _download(Uri.parse(track.uri), file);
    } catch (e) {
      debugPrint('No se pudo guardar ${track.id} en la caché: $e');
    } finally {
      _saving.remove(track.id);
    }
  }

  /// Descarga a un `.part` y lo renombra solo si llegaron todos los bytes
  /// declarados; si no, lo borra y falla.
  static Future<void> httpDownload(Uri uri, File target) async {
    final part = File('${target.path}.part');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final sink = part.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          received += chunk.length;
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (response.contentLength >= 0 && received != response.contentLength) {
        throw HttpException(
          'Descarga incompleta: $received de ${response.contentLength} bytes',
          uri: uri,
        );
      }
      await part.rename(target.path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  /// Hay copia completa: existe el archivo y no quedó una descarga a medias.
  static Future<bool> _isComplete(File file) async =>
      await file.exists() && !await File('${file.path}.part').exists();

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
