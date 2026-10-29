import 'dart:convert';
import 'dart:io';

import '../../dto/audius_track_dto.dart';

typedef HttpGet = Future<String> Function(Uri uri);

/// Cliente de la API pública de Audius: gratuita, sin clave y sin anuncios.
class AudiusRemoteDataSource {
  static const String _host = 'api.audius.co';

  /// Audius pide identificar la app en cada petición.
  static const String appName = 'pulso';

  static const Duration _timeout = Duration(seconds: 15);

  final HttpGet _httpGet;

  AudiusRemoteDataSource({HttpGet? httpGet}) : _httpGet = httpGet ?? _get;

  /// URL de streaming de una pista; Audius redirige al nodo que la sirve.
  static Uri streamUri(String trackId) =>
      Uri.https(_host, '/v1/tracks/$trackId/stream', {'app_name': appName});

  Future<List<AudiusTrackDto>> searchTracks(String query) async {
    final uri = Uri.https(_host, '/v1/tracks/search', {
      'query': query,
      'app_name': appName,
    });

    final body = jsonDecode(await _httpGet(uri));
    if (body is! Map<String, dynamic> || body['data'] is! List) {
      throw const FormatException('Respuesta de Audius sin lista de pistas');
    }

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(AudiusTrackDto.fromJson)
        .toList();
  }

  static Future<String> _get(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(_timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return body;
    } finally {
      client.close();
    }
  }
}
