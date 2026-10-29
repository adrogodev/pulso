import 'package:pulso/shared/base_domain/result/result.dart';

/// Contrato del repositorio para configuración y preferencias locales.
abstract class SettingsRepository {
  Future<Result<String?>> getPreference(String key);
  Future<Result<void>> setPreference(String key, String value);
  Future<Result<Map<String, dynamic>?>> getLastSession();
  Future<Result<void>> saveLastSession(String trackId, int positionMs);
}
