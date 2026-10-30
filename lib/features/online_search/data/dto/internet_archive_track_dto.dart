import '../data_sources/remote/http_get.dart';

/// Pista de un ítem de audio de Internet Archive: grabaciones antiguas, de
/// dominio público y conciertos en vivo que se escuchan completos.
class InternetArchiveTrackDto {
  final String itemId;
  final String fileName;
  final String title;
  final String artistName;
  final String albumTitle;
  final int durationSeconds;
  final int? year;

  const InternetArchiveTrackDto({
    required this.itemId,
    required this.fileName,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.durationSeconds,
    this.year,
  });

  /// Cada archivo se sirve desde `/download/<ítem>/<archivo>`.
  Uri get audioUri => Uri.https('archive.org', '/download/$itemId/$fileName');

  /// Miniatura que Internet Archive genera para cada ítem.
  String get artworkUrl => 'https://archive.org/services/img/$itemId';

  /// Las pistas MP3 de la respuesta de `/metadata/<ítem>`, como máximo
  /// [maxTracks]. Un ítem sin título ni archivos MP3 no aporta pistas.
  static List<InternetArchiveTrackDto> fromMetadata(
    String itemId,
    Map<String, dynamic> json, {
    int maxTracks = 5,
  }) {
    final metadata = json['metadata'];
    final files = json['files'];
    if (metadata is! Map || files is! List) return const [];

    final album = textOr(_first(metadata['title']), itemId);
    final artist = textOr(_first(metadata['creator']), 'Artista desconocido');
    // "year" o "date" ("1957", "1957-03-01"): solo interesan los 4 dígitos.
    final date =
        '${_first(metadata['year']) ?? _first(metadata['date']) ?? ''}';
    final year = date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;

    final tracks = <InternetArchiveTrackDto>[];
    final seenTitles = <String>{};
    for (final file in files.whereType<Map<String, dynamic>>()) {
      final name = file['name'];
      if (name is! String || !name.toLowerCase().endsWith('.mp3')) continue;

      final title = textOr(file['title'], _withoutExtension(name));
      // Un mismo tema puede venir en varias calidades de MP3.
      if (!seenTitles.add(title.toLowerCase())) continue;

      tracks.add(
        InternetArchiveTrackDto(
          itemId: itemId,
          fileName: name,
          title: title,
          artistName: textOr(file['creator'] ?? file['artist'], artist),
          albumTitle: album,
          durationSeconds: _parseLength(file['length']),
          year: year,
        ),
      );
      if (tracks.length >= maxTracks) break;
    }
    return tracks;
  }

  static Object? _first(Object? value) =>
      value is List ? (value.isEmpty ? null : value.first) : value;

  static String _withoutExtension(String name) {
    final base = name.split('/').last;
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }

  /// La duración llega en segundos ("245.3") o como "mm:ss" / "hh:mm:ss".
  static int _parseLength(Object? value) {
    final text = '${value ?? ''}'.trim();
    if (text.contains(':')) {
      return text
          .split(':')
          .map((part) => int.tryParse(part) ?? 0)
          .fold(0, (total, part) => total * 60 + part);
    }
    return double.tryParse(text)?.round() ?? 0;
  }
}
