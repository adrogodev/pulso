import 'dart:convert';
import 'dart:io';

/// Descarga el cuerpo de una URL como texto; se inyecta en los tests.
typedef HttpGet = Future<String> Function(Uri uri);

const Duration _timeout = Duration(seconds: 15);

/// GET con tiempo límite que falla con [HttpException] si la respuesta no es
/// 200. Lo comparten todas las fuentes en línea.
Future<String> httpGetText(Uri uri) async {
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

/// Decodifica una respuesta JSON que debe ser un objeto.
Map<String, dynamic> decodeJsonObject(String body, String source) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Respuesta de $source sin objeto JSON');
  }
  return decoded;
}

/// Solo se aceptan URLs https: llegan a la notificación del sistema, a
/// Image.network y al reproductor.
String? httpsUrlOrNull(Object? url) {
  if (url is! String) return null;
  final uri = Uri.tryParse(url);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
      ? url
      : null;
}

/// Texto no vacío o [fallback].
String textOr(Object? value, String fallback) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;
