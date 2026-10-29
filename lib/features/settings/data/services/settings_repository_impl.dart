import 'package:pulso/shared/base_data/database/database_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

import '../../domain/services/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseService _dbService;

  SettingsRepositoryImpl(this._dbService);

  @override
  Future<Result<String?>> getPreference(String key) async {
    try {
      final value = await _dbService.getPreference(key);
      return Result.ok(value);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al leer preferencia: $key', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> setPreference(String key, String value) async {
    try {
      await _dbService.setPreference(key, value);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al guardar preferencia: $key', cause: e),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> getLastSession() async {
    try {
      final trackId = await _dbService.getPreference('last_session_track_id');
      final positionStr = await _dbService.getPreference(
        'last_session_position_ms',
      );

      if (trackId == null || trackId.isEmpty) {
        return const Result.ok(null);
      }

      final positionMs = int.tryParse(positionStr ?? '0') ?? 0;
      return Result.ok({'trackId': trackId, 'positionMs': positionMs});
    } catch (e) {
      return Result.err(
        StorageFailure('Error al obtener última sesión', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> saveLastSession(String trackId, int positionMs) async {
    try {
      await _dbService.setPreference('last_session_track_id', trackId);
      await _dbService.setPreference(
        'last_session_position_ms',
        positionMs.toString(),
      );
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al guardar última sesión', cause: e),
      );
    }
  }
}
