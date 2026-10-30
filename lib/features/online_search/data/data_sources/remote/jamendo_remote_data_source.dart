import '../../dto/jamendo_track_dto.dart';
import 'http_get.dart';

/// API v3 de Jamendo. Exige un `client_id` gratuito que se obtiene en
/// https://devportal.jamendo.com.
class JamendoRemoteDataSource {
  static const int _limit = 30;

  final HttpGet _httpGet;
  final String clientId;

  JamendoRemoteDataSource({required this.clientId, HttpGet? httpGet})
    : _httpGet = httpGet ?? httpGetText;

  Future<List<JamendoTrackDto>> searchTracks(String query) async {
    final uri = Uri.https('api.jamendo.com', '/v3.0/tracks/', {
      'client_id': clientId,
      'format': 'json',
      'limit': '$_limit',
      'search': query,
      'audioformat': 'mp32',
      'imagesize': '300',
    });

    final body = decodeJsonObject(await _httpGet(uri), 'Jamendo');
    final headers = body['headers'];
    if (headers is Map && headers['status'] != 'success') {
      throw FormatException('Jamendo respondió: ${headers['error_message']}');
    }
    if (body['results'] is! List) {
      throw const FormatException('Respuesta de Jamendo sin resultados');
    }

    return (body['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map(JamendoTrackDto.tryFromJson)
        .whereType<JamendoTrackDto>()
        .toList();
  }
}
