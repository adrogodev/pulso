import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/favorites/presentation/providers/favorites_notifier.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SettingsRepositoryImpl(dbService);
});

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  SettingsState build() {
    loadSettings();
    return const SettingsState();
  }

  Future<void> loadSettings() async {
    final restorePref = await _repo.getPreference('restore_last_session');
    final autoRescanPref = await _repo.getPreference('auto_rescan_on_launch');

    state = state.copyWith(
      restoreLastSession: restorePref.dataOrNull != 'false',
      autoRescanOnLaunch: autoRescanPref.dataOrNull != 'false',
    );
  }

  Future<void> setRestoreLastSession(bool value) async {
    state = state.copyWith(restoreLastSession: value);
    await _repo.setPreference('restore_last_session', value.toString());
  }

  Future<void> setAutoRescanOnLaunch(bool value) async {
    state = state.copyWith(autoRescanOnLaunch: value);
    await _repo.setPreference('auto_rescan_on_launch', value.toString());
  }
}
