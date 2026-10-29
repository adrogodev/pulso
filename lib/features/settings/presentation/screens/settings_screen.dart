import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/shared/ui_kit/theme/app_colors.dart';
import 'package:pulso/shared/ui_kit/theme/app_typography.dart';
import 'package:pulso/features/library/presentation/controllers/library_notifier.dart';
import 'package:pulso/shared/ui_kit/widgets/pulso_waveform.dart';

import '../controllers/settings_notifier.dart';

/// Pantalla de configuración, estado de permisos y preferencias locales de Pulso.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final libraryState = ref.watch(libraryNotifierProvider);
    final libraryNotifier = ref.read(libraryNotifierProvider.notifier);
    final permissionService = ref.watch(permissionServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('CONFIGURACIÓN', style: AppTypography.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Encabezado de identidad
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                const PulsoWaveform(width: 56, height: 56),
                const SizedBox(height: 12),
                const Text(
                  'Pulso',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión ${settings.appVersion} • Música local offline',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección: Biblioteca y Archivos
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'BIBLIOTECA Y ARCHIVOS',
              style: AppTypography.labelSmall,
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text(
                    'Actualizar biblioteca',
                    style: AppTypography.bodyLarge,
                  ),
                  subtitle: Text(
                    '${libraryState.tracks.length} canciones encontradas',
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: libraryState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.iconMuted,
                        ),
                  onTap: libraryState.isLoading
                      ? null
                      : () async {
                          await libraryNotifier.refreshLibrary();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Biblioteca actualizada'),
                                backgroundColor: AppColors.surfaceElevated,
                              ),
                            );
                          }
                        },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    libraryState.hasPermission
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: libraryState.hasPermission
                        ? AppColors.textPrimary
                        : AppColors.iconMuted,
                  ),
                  title: const Text(
                    'Permisos de audio',
                    style: AppTypography.bodyLarge,
                  ),
                  subtitle: Text(
                    libraryState.hasPermission
                        ? 'Acceso multimedia concedido'
                        : 'Acceso denegado o no solicitado',
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      if (!libraryState.hasPermission) {
                        await libraryNotifier.requestPermissions();
                      } else {
                        await permissionService.openSettings();
                      }
                    },
                    child: Text(
                      libraryState.hasPermission ? 'Ajustes' : 'Conceder',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección: Preferencias
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('PREFERENCIAS', style: AppTypography.labelSmall),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.restoreLastSession,
                  onChanged: (val) =>
                      settingsNotifier.setRestoreLastSession(val),
                  activeThumbColor: AppColors.textPrimary,
                  title: const Text(
                    'Recordar última sesión',
                    style: AppTypography.bodyLarge,
                  ),
                  subtitle: const Text(
                    'Restaura la pista actual al iniciar la aplicación',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  value: settings.autoRescanOnLaunch,
                  onChanged: (val) =>
                      settingsNotifier.setAutoRescanOnLaunch(val),
                  activeThumbColor: AppColors.textPrimary,
                  title: const Text(
                    'Reescanear al abrir',
                    style: AppTypography.bodyLarge,
                  ),
                  subtitle: const Text(
                    'Detecta nuevas canciones descargadas automáticamente',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección: Legal y Licencias
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('INFORMACIÓN', style: AppTypography.labelSmall),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.policy_rounded,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Licencias de código abierto',
                    style: AppTypography.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.iconMuted,
                  ),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Pulso',
                      applicationVersion: settings.appVersion,
                      applicationIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: PulsoWaveform(width: 48, height: 48),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
