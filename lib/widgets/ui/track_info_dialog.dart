import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/utils/metadata_formatter.dart';
import '../../entities/track/track.dart';

/// Diálogo que muestra los detalles técnicos y metadatos de un archivo de audio.
class TrackInfoDialog extends StatelessWidget {
  final Track track;

  const TrackInfoDialog({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => TrackInfoDialog(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeStr = MetadataFormatter.formatFileSize(track.size);
    final durationStr = MetadataFormatter.formatDurationMs(
      track.duration.inMilliseconds,
    );

    return AlertDialog(
      title: const Text(
        'Información del archivo',
        style: AppTypography.titleMedium,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Título', track.title),
            _buildRow('Artista', track.artist),
            _buildRow('Álbum', track.album),
            _buildRow('Duración', durationStr),
            _buildRow(
              'Formato',
              (track.fileExtension ?? 'AUDIO').toUpperCase(),
            ),
            if (sizeStr.isNotEmpty) _buildRow('Tamaño', sizeStr),
            if (track.year != null && track.year! > 0)
              _buildRow('Año', track.year.toString()),
            if (track.trackNumber != null && track.trackNumber! > 0)
              _buildRow('Pista', track.trackNumber.toString()),
            const SizedBox(height: 8),
            const Text('Ubicación / URI', style: AppTypography.labelSmall),
            const SizedBox(height: 4),
            SelectableText(
              track.uri,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
