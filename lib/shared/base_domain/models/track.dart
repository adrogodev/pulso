import 'package:flutter/foundation.dart';

/// Entidad pura e inmutable que representa una pista de audio local.
@immutable
class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final int? trackNumber;
  final String? genre;
  final int? year;
  final String uri;
  final String? fileExtension;
  final int? albumId;
  final int? size;
  final int? dateAdded;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.uri,
    this.trackNumber,
    this.genre,
    this.year,
    this.fileExtension,
    this.albumId,
    this.size,
    this.dateAdded,
  });

  /// Duración tipada en objeto [Duration].
  Duration get duration => Duration(milliseconds: durationMs);

  /// Duración formateada de forma compacta (ej. "03:45" o "1:15:20").
  String get formattedDuration {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Comprueba si la extensión del archivo es uno de los formatos soportados.
  bool get isSupportedFormat {
    final ext = fileExtension?.toLowerCase().replaceAll('.', '');
    if (ext == null) return true;
    return const {'mp3', 'aac', 'm4a', 'wav', 'flac', 'ogg'}.contains(ext);
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    int? trackNumber,
    String? genre,
    int? year,
    String? uri,
    String? fileExtension,
    int? albumId,
    int? size,
    int? dateAdded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      trackNumber: trackNumber ?? this.trackNumber,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      uri: uri ?? this.uri,
      fileExtension: fileExtension ?? this.fileExtension,
      albumId: albumId ?? this.albumId,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == id &&
          other.title == title &&
          other.artist == artist &&
          other.album == album &&
          other.durationMs == durationMs &&
          other.uri == uri);

  @override
  int get hashCode => Object.hash(id, title, artist, album, durationMs, uri);

  @override
  String toString() =>
      'Track(id: $id, title: $title, artist: $artist, album: $album)';
}
