import 'dart:async';

import '../../../../shared/base_domain/error/failures.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';
import '../../domain/services/online_music_service.dart';

/// Busca en varias fuentes a la vez y devuelve una sola lista.
///
/// - Las fuentes se consultan en paralelo; la que supera [timeout] o falla se
///   descarta y la búsqueda sigue con el resto.
/// - Una misma canción (mismo título y algún artista en común) aparece una
///   sola vez, aunque una fuente agregue "(Remastered)" o más créditos: se
///   conserva la de la fuente que va antes en [sources].
/// - Primero va lo que más coincide con la búsqueda; con la misma
///   relevancia, se alternan las fuentes respetando el orden de cada una.
class MultiSourceMusicService implements OnlineMusicService {
  static const Duration defaultTimeout = Duration(seconds: 12);
  static const int defaultMaxResults = 120;

  final List<OnlineMusicService> sources;
  final Duration timeout;
  final int maxResults;

  MultiSourceMusicService(
    this.sources, {
    this.timeout = defaultTimeout,
    this.maxResults = defaultMaxResults,
  });

  @override
  Future<Result<List<Track>>> searchTracks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Result.ok([]);

    final results = await Future.wait(
      sources.map((source) => _search(source, trimmed)),
    );

    final found = results.where((r) => r.isSuccess).toList();
    if (found.isEmpty) {
      return results.isEmpty
          ? const Result.ok([])
          : Result.err(results.first.failureOrNull!);
    }

    return Result.ok(_merge(results, trimmed));
  }

  Future<Result<List<Track>>> _search(OnlineMusicService source, String query) {
    return source
        .searchTracks(query)
        .timeout(
          timeout,
          onTimeout: () => const Result.err(
            NetworkFailure('La búsqueda en línea tardó demasiado.'),
          ),
        );
  }

  List<Track> _merge(List<Result<List<Track>>> results, String query) {
    final queryText = normalize(query);
    final queryWords = queryText.split(' ').where((w) => w.isNotEmpty).toSet();

    // Canciones agrupadas por título; dentro del grupo, son la misma si
    // comparten al menos un artista.
    final byTitle = <String, List<_Ranked>>{};
    for (var source = 0; source < results.length; source++) {
      final tracks = results[source].dataOrNull ?? const <Track>[];
      for (var position = 0; position < tracks.length; position++) {
        final track = tracks[position];
        final artists = artistNames(track.artist);
        final candidate = _Ranked(
          track,
          artists: artists,
          score: _relevance(track, artists, queryText, queryWords),
          position: position,
          source: source,
        );

        final group = byTitle.putIfAbsent(_titleKey(track.title), () => []);
        final same = group.indexWhere((r) => r.artists.any(artists.contains));
        if (same == -1) group.add(candidate);
      }
    }

    final ranked = byTitle.values.expand((group) => group).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : a.source.compareTo(b.source);
      });
    return ranked.take(maxResults).map((r) => r.track).toList(growable: false);
  }

  /// Fracción de palabras de la búsqueda presentes en título, artista y
  /// álbum, con un extra si aparece la frase completa y otro si es
  /// exactamente uno de los artistas.
  static double _relevance(
    Track track,
    Set<String> artists,
    String queryText,
    Set<String> words,
  ) {
    if (words.isEmpty) return 0;
    final text = normalize('${track.title} ${track.artist} ${track.album}');
    final present = text.split(' ').toSet();
    final matched = words.where(present.contains).length / words.length;
    return matched +
        (' $text '.contains(' $queryText ') ? 0.5 : 0) +
        (artists.contains(queryText) ? 0.5 : 0);
  }

  /// Título sin versiones ni colaboraciones entre paréntesis o corchetes:
  /// "Lejos (Remastered)" y "Lejos" son la misma canción.
  static String _titleKey(String title) =>
      normalize(title.replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]'), ' '));

  static final RegExp _artistSeparator = RegExp(
    r',|&|;|\s+(?:feat\.?|ft\.?|featuring|x|y|and|with)\s+',
    caseSensitive: false,
  );

  /// Cada artista de un crédito como "A, B & C feat. D", normalizado.
  static Set<String> artistNames(String credit) => credit
      .split(_artistSeparator)
      .map(normalize)
      .where((name) => name.isNotEmpty)
      .toSet();

  static const Map<String, String> _accents = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };

  /// Minúsculas, sin tildes y con un solo espacio entre palabras, para
  /// comparar textos de fuentes distintas.
  static String normalize(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

class _Ranked {
  final Track track;
  final Set<String> artists;
  final double score;
  final int position;
  final int source;

  const _Ranked(
    this.track, {
    required this.artists,
    required this.score,
    required this.position,
    required this.source,
  });
}
