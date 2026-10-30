import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/utils/metadata_formatter.dart';
import '../../../playback/presentation/controllers/playback_notifier.dart';

/// Muestra cuánto ocupa la música en línea guardada y permite vaciarla.
class OnlineCacheTile extends ConsumerStatefulWidget {
  const OnlineCacheTile({super.key});

  @override
  ConsumerState<OnlineCacheTile> createState() => _OnlineCacheTileState();
}

class _OnlineCacheTileState extends ConsumerState<OnlineCacheTile> {
  /// Bytes guardados; `null` mientras se calcula. Se guarda en el estado y no
  /// en un FutureBuilder, que mostraría el tamaño viejo tras vaciar la caché.
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    int bytes;
    try {
      bytes = await ref.read(onlineAudioCacheProvider).sizeBytes();
    } catch (_) {
      // Sin directorio de caché (por ejemplo, fuera de Android): nada guardado.
      bytes = 0;
    }
    if (mounted) setState(() => _bytes = bytes);
  }

  Future<void> _clear() async {
    await ref.read(onlineAudioCacheProvider).clear();
    if (mounted) setState(() => _bytes = 0);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes ?? 0;
    return ListTile(
      leading: const Icon(
        Icons.cloud_download_outlined,
        color: AppColors.iconActive,
      ),
      title: const Text(
        'Caché de música en línea',
        style: AppTypography.bodyLarge,
      ),
      subtitle: Text(
        _bytes == null
            ? 'Calculando…'
            : bytes > 0
            ? '${MetadataFormatter.formatFileSize(bytes)} guardados'
            : 'Sin canciones guardadas',
        style: AppTypography.bodyMedium,
      ),
      trailing: bytes > 0
          ? TextButton(onPressed: _clear, child: const Text('Vaciar'))
          : null,
    );
  }
}
