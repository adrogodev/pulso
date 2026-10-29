import 'package:flutter/foundation.dart';

@immutable
class SettingsState {
  final bool restoreLastSession;

  /// Oculta notas de voz y clips cortos sin artista de la biblioteca.
  final bool hideShortClips;
  final String appVersion;

  const SettingsState({
    this.restoreLastSession = true,
    this.hideShortClips = true,
    this.appVersion = '1.0.0',
  });

  SettingsState copyWith({
    bool? restoreLastSession,
    bool? hideShortClips,
    String? appVersion,
  }) {
    return SettingsState(
      restoreLastSession: restoreLastSession ?? this.restoreLastSession,
      hideShortClips: hideShortClips ?? this.hideShortClips,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
