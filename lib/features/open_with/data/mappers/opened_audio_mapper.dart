import '../../../../shared/base_domain/models/track.dart';
import '../../domain/models/opened_audio.dart';

/// Convierte un audio abierto desde otra app en una pista reproducible.
///
/// La duración queda en 0: el reproductor la informa al cargar el archivo.
Track trackFromOpenedAudio(OpenedAudio audio) {
  final name = _fileName(audio);
  final dot = name?.lastIndexOf('.') ?? -1;
  final hasExtension = name != null && dot > 0 && dot < name.length - 1;

  return Track(
    id: 'external:${audio.uri}',
    title: hasExtension ? name.substring(0, dot) : (name ?? 'Audio'),
    artist: Track.unknownArtist,
    album: 'Audio externo',
    durationMs: 0,
    uri: audio.uri,
    fileExtension: hasExtension ? name.substring(dot + 1).toLowerCase() : null,
  );
}

String? _fileName(OpenedAudio audio) {
  final given = audio.displayName?.trim();
  if (given != null && given.isNotEmpty) return given;

  final segments = Uri.tryParse(audio.uri)?.pathSegments ?? const [];
  final last = segments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
  return last.isEmpty ? null : last;
}
