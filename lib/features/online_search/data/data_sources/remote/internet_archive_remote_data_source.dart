import '../../dto/internet_archive_track_dto.dart';
import 'http_get.dart';

/// Búsqueda en las colecciones de audio de Internet Archive, sin clave.
///
/// La búsqueda devuelve ítems (álbumes, conciertos); los archivos de cada
/// uno se piden en paralelo a /metadata.
class InternetArchiveRemoteDataSource {
  static const int _items = 6;

  final HttpGet _httpGet;

  InternetArchiveRemoteDataSource({HttpGet? httpGet})
    : _httpGet = httpGet ?? httpGetText;

  Future<List<InternetArchiveTrackDto>> searchTracks(String query) async {
    final uri = Uri.https('archive.org', '/advancedsearch.php', {
      'q': '(${_escape(query)}) AND mediatype:(audio)',
      'fl[]': 'identifier',
      'rows': '$_items',
      'output': 'json',
    });

    final body = decodeJsonObject(await _httpGet(uri), 'Internet Archive');
    final response = body['response'];
    if (response is! Map || response['docs'] is! List) {
      throw const FormatException('Respuesta de Internet Archive sin ítems');
    }

    final ids = (response['docs'] as List)
        .whereType<Map<String, dynamic>>()
        .map((doc) => doc['identifier'])
        .whereType<String>()
        .where((id) => id.isNotEmpty);

    final perItem = await Future.wait(ids.map(_tracksOf));
    return perItem.expand((tracks) => tracks).toList();
  }

  /// Un ítem que no responde no invalida al resto.
  Future<List<InternetArchiveTrackDto>> _tracksOf(String id) async {
    try {
      final uri = Uri.https('archive.org', '/metadata/$id');
      final body = decodeJsonObject(await _httpGet(uri), 'Internet Archive');
      return InternetArchiveTrackDto.fromMetadata(id, body);
    } catch (_) {
      return const [];
    }
  }

  /// Quita la sintaxis de consulta de Lucene para buscar el texto tal cual.
  static String _escape(String query) =>
      query.replaceAll(RegExp(r'[+\-&|!(){}\[\]^"~*?:\\/]'), ' ').trim();
}
