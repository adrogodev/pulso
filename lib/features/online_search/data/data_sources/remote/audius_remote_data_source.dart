import '../../dto/audius_track_dto.dart';
import 'http_get.dart';

export 'http_get.dart' show HttpGet;

/// Cliente de la API pública de Audius: gratuita, sin clave y sin anuncios.
class AudiusRemoteDataSource {
  static const String _host = 'api.audius.co';

  /// Audius pide identificar la app en cada petición.
  static const String appName = 'pulso';

  final HttpGet _httpGet;

  AudiusRemoteDataSource({HttpGet? httpGet})
    : _httpGet = httpGet ?? httpGetText;

  /// URL de streaming de una pista; Audius redirige al nodo que la sirve.
  static Uri streamUri(String trackId) =>
      Uri.https(_host, '/v1/tracks/$trackId/stream', {'app_name': appName});

  Future<List<AudiusTrackDto>> searchTracks(String query) async {
    final uri = Uri.https(_host, '/v1/tracks/search', {
      'query': query,
      'app_name': appName,
    });

    final body = decodeJsonObject(await _httpGet(uri), 'Audius');
    if (body['data'] is! List) {
      throw const FormatException('Respuesta de Audius sin lista de pistas');
    }

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(AudiusTrackDto.tryFromJson)
        .whereType<AudiusTrackDto>()
        .toList();
  }
}
