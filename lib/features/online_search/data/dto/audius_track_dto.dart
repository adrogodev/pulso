/// Pista tal como la devuelve la API pública de Audius.
///
/// Solo se usa dentro de la capa de datos; el resto de la app trabaja con
/// [Track] a través de `AudiusTrackMapper`.
class AudiusTrackDto {
  final String id;
  final String title;
  final String artistName;
  final int durationSeconds;
  final String? genre;
  final String? artworkUrl;
  final bool isStreamable;

  const AudiusTrackDto({
    required this.id,
    required this.title,
    required this.artistName,
    required this.durationSeconds,
    required this.isStreamable,
    this.genre,
    this.artworkUrl,
  });

  factory AudiusTrackDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final artwork = json['artwork'] as Map<String, dynamic>?;
    final genre = json['genre'] as String?;

    return AudiusTrackDto(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sin título',
      artistName: user?['name'] as String? ?? 'Artista desconocido',
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      genre: (genre == null || genre.isEmpty) ? null : genre,
      artworkUrl: artwork?['480x480'] as String?,
      // Audius marca explícitamente las pistas bloqueadas; si el campo no
      // viene, la pista se considera reproducible.
      isStreamable: json['is_streamable'] as bool? ?? true,
    );
  }
}
