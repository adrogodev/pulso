/// Utilidades de formateo de metadatos de audio para Pulso.
abstract final class MetadataFormatter {
  /// Formatea milisegundos a formato legible mm:ss o h:mm:ss.
  static String formatDurationMs(int ms) {
    if (ms <= 0) return '00:00';
    final totalSeconds = (ms / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minStr:$secStr';
    }
    return '$minStr:$secStr';
  }

  /// Formatea el tamaño de archivo en bytes a KB o MB.
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Formatea el número de pista para listas y álbumes.
  static String formatTrackNumber(int? track) {
    if (track == null || track <= 0) return '';
    return track.toString().padLeft(2, '0');
  }

  /// Cantidad de canciones con el sustantivo en singular o plural.
  static String formatSongCount(int count) =>
      count == 1 ? '1 canción' : '$count canciones';
}
