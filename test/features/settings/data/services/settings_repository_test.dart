import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_data/database/memory_database_service.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/features/settings/data/services/settings_repository_impl.dart';

void main() {
  group('SettingsRepositoryImpl', () {
    late MemoryDatabaseService dbService;
    late SettingsRepositoryImpl repository;

    setUp(() {
      dbService = MemoryDatabaseService();
      repository = SettingsRepositoryImpl(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('guarda y recupera preferencias correctamente', () async {
      final initial = await repository.getPreference('tema_oscuro');
      expect((initial as Success<String?>).data, isNull);

      await repository.setPreference('tema_oscuro', 'true');
      final updated = await repository.getPreference('tema_oscuro');
      expect((updated as Success<String?>).data, 'true');
    });

    test('guarda y recupera la última sesión de reproducción', () async {
      final initial = await repository.getLastSession();
      expect((initial as Success<Map<String, dynamic>?>).data, isNull);

      await repository.saveLastSession('track-100', 45000);
      final sessionRes = await repository.getLastSession();
      final session = (sessionRes as Success<Map<String, dynamic>?>).data;

      expect(session, isNotNull);
      expect(session!['trackId'], 'track-100');
      expect(session['positionMs'], 45000);
    });

    test('olvida la última sesión guardada', () async {
      await repository.saveLastSession('track-100', 45000);

      await repository.clearLastSession();

      expect((await repository.getLastSession()).dataOrNull, isNull);
    });
  });
}
