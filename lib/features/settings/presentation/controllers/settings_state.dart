import 'package:flutter/foundation.dart';

@immutable
class SettingsState {
  final bool restoreLastSession;
  final bool autoRescanOnLaunch;
  final String appVersion;

  const SettingsState({
    this.restoreLastSession = true,
    this.autoRescanOnLaunch = true,
    this.appVersion = '1.0.0',
  });

  SettingsState copyWith({
    bool? restoreLastSession,
    bool? autoRescanOnLaunch,
    String? appVersion,
  }) {
    return SettingsState(
      restoreLastSession: restoreLastSession ?? this.restoreLastSession,
      autoRescanOnLaunch: autoRescanOnLaunch ?? this.autoRescanOnLaunch,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
