/// Pista tal como la devuelve la API pública de Audius.
///
/// Solo se usa dentro de la capa de datos; el resto de la app trabaja con
/// `Track` a través de `AudiusTrackMapper`.
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

  /// Interpreta un resultado de la API, o devuelve `null` si no tiene `id`.
  ///
  /// Es tolerante a propósito: un resultado malformado se descarta solo, sin
  /// invalidar el resto de la página de resultados.
  static AudiusTrackDto? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;

    final user = json['user'];
    final artwork = json['artwork'];
    final title = json['title'];
    final genre = json['genre'];
    final duration = json['duration'];
    final isStreamable = json['is_streamable'];

    return AudiusTrackDto(
      id: id,
      title: title is String && title.isNotEmpty ? title : 'Sin título',
      artistName: user is Map && user['name'] is String
          ? user['name'] as String
          : 'Artista desconocido',
      durationSeconds: duration is num ? duration.toInt() : 0,
      genre: genre is String && genre.isNotEmpty ? genre : null,
      artworkUrl: artwork is Map ? _httpsOnly(artwork['480x480']) : null,
      // Audius marca explícitamente las pistas bloqueadas; si el campo no
      // viene, la pista se considera reproducible.
      isStreamable: isStreamable is bool ? isStreamable : true,
    );
  }

  /// La carátula llega a la notificación del sistema y a Image.network, así
  /// que solo se aceptan URLs https.
  static String? _httpsOnly(Object? url) {
    if (url is! String) return null;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? url
        : null;
  }
}
