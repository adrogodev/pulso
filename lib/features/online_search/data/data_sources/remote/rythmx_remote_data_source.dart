import '../../dto/rythmx_track_dto.dart';
import 'http_get.dart';

export 'http_get.dart' show HttpGet;

/// Cliente de la API propia de Rythmx: busca en YouTube Music y entrega una
/// URL de streaming de audio por canción.
class RythmxRemoteDataSource {
  /// Canciones por búsqueda (la API admite hasta 50).
  static const int limit = 30;

  final HttpGet _httpGet;

  /// URL base del servidor, por ejemplo `http://localhost:8000`.
  final String baseUrl;

  RythmxRemoteDataSource({required this.baseUrl, HttpGet? httpGet})
    : _httpGet = httpGet ?? httpGetText;

  Future<List<RythmxTrackDto>> searchTracks(String query) async {
    final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
    final uri = base
        .resolve('api/search')
        .replace(
          queryParameters: {
            'query': query,
            'filter': 'songs',
            'limit': '$limit',
          },
        );

    final body = decodeJsonObject(await _httpGet(uri), 'Rythmx');
    final data = body['data'];
    if (body['success'] != true ||
        data is! Map<String, dynamic> ||
        data['songs'] is! List) {
      throw FormatException('Rythmx respondió: ${body['message']}');
    }

    return (data['songs'] as List)
        .whereType<Map<String, dynamic>>()
        .map(RythmxTrackDto.tryFromJson)
        .whereType<RythmxTrackDto>()
        .toList();
  }
}
