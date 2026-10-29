import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';

import '../../data/services/settings_repository_impl.dart';
import '../../domain/services/settings_repository.dart';
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
    final hideClipsPref = await _repo.getPreference('hide_short_clips');

    state = state.copyWith(
      restoreLastSession: restorePref.dataOrNull != 'false',
      hideShortClips: hideClipsPref.dataOrNull != 'false',
    );
  }

  Future<void> setRestoreLastSession(bool value) async {
    state = state.copyWith(restoreLastSession: value);
    await _repo.setPreference('restore_last_session', value.toString());
  }

  Future<void> setHideShortClips(bool value) async {
    state = state.copyWith(hideShortClips: value);
    await _repo.setPreference('hide_short_clips', value.toString());
  }
}
