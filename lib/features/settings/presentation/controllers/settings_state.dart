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
    // Mantener en sincronía con `version` de pubspec.yaml.
    this.appVersion = '0.0.1',
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
