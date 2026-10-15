import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isAndroid) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'dev.adrogo.pulso.channel.audio',
        androidNotificationChannelName: 'Pulso Reproducción',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      );
    } catch (e) {
      debugPrint('Error inicializando JustAudioBackground: $e');
    }
  }

  runApp(const ProviderScope(child: PulsoApp()));
}
