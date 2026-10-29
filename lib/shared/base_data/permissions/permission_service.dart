import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../base_domain/error/failures.dart';
import '../../base_domain/result/result.dart';

/// Contrato abstracto para la gestión de permisos en Pulso.
abstract class PermissionService {
  Future<Result<bool>> hasAudioPermission();
  Future<Result<bool>> requestAudioPermission();
  Future<bool> openSettings();
}

/// Implementación real utilizando [permission_handler] adaptada para Android Scoped Storage.
class PermissionServiceImpl implements PermissionService {
  const PermissionServiceImpl();

  @override
  Future<Result<bool>> hasAudioPermission() async {
    try {
      if (!Platform.isAndroid) {
        return const Result.ok(true);
      }

      // En Android 13+ (API 33+) se consulta Permission.audio (READ_MEDIA_AUDIO)
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted || audioStatus.isLimited) {
        return const Result.ok(true);
      }

      // En Android 12 o inferior se consulta Permission.storage
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return const Result.ok(true);
      }

      return const Result.ok(false);
    } catch (e) {
      return Result.err(
        PermissionFailure('Error al verificar permisos de audio', cause: e),
      );
    }
  }

  @override
  Future<Result<bool>> requestAudioPermission() async {
    try {
      if (!Platform.isAndroid) {
        return const Result.ok(true);
      }

      // Intentar solicitar permiso de audio (Android 13+)
      var status = await Permission.audio.request();

      // Si no fue concedido o no aplica (Android <= 12), solicitar almacenamiento
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.storage.request();
      }

      if (status.isGranted || status.isLimited) {
        return const Result.ok(true);
      }

      return Result.err(
        PermissionFailure(
          'Permiso para acceder a los archivos de audio denegado',
          isPermanentlyDenied: status.isPermanentlyDenied,
          cause: null,
        ),
      );
    } catch (e) {
      return Result.err(
        PermissionFailure('Excepción al solicitar permisos de audio', cause: e),
      );
    }
  }

  @override
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
