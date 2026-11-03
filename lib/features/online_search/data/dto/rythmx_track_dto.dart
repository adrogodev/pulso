import '../data_sources/remote/http_get.dart';

/// Canción de la API de Rythmx (catálogo de YouTube Music) con su URL de
/// streaming de audio.
class RythmxTrackDto {
  final String id;
  final String title;
  final List<String> artistNames;
  final String? albumTitle;
  final int durationSeconds;
  final String streamUrl;
  final String? thumbnailUrl;

  const RythmxTrackDto({
    required this.id,
    required this.title,
    required this.artistNames,
    required this.durationSeconds,
    required this.streamUrl,
    this.albumTitle,
    this.thumbnailUrl,
  });

  static RythmxTrackDto? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final stream = _streamUrlOrNull(json['stream_url']);
    if (id is! String || id.isEmpty || stream == null) return null;

    final artists = json['artists'];
    final album = json['album'];
    final duration = json['duration_seconds'];
    return RythmxTrackDto(
      id: id,
      title: textOr(json['title'], 'Sin título'),
      artistNames: [
        if (artists is List)
          for (final artist in artists.whereType<Map<String, dynamic>>())
            if (artist['name'] case final String name
                when name.trim().isNotEmpty)
              name.trim(),
      ],
      albumTitle: album is Map<String, dynamic>
          ? textOr(album['title'], '').nullIfEmpty
          : null,
      durationSeconds: duration is num ? duration.toInt() : 0,
      streamUrl: stream,
      thumbnailUrl: httpsUrlOrNull(json['thumbnail']),
    );
  }

  /// El servidor propio puede servir el audio por http (por ejemplo, en
  /// desarrollo a través de `adb reverse`); se rechaza cualquier otro esquema.
  static String? _streamUrlOrNull(Object? url) {
    if (url is! String) return null;
    final uri = Uri.tryParse(url);
    return uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty
        ? url
        : null;
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
