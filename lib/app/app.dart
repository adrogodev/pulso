import 'package:flutter/material.dart';

import '../features/open_with/presentation/widgets/opened_audio_listener.dart';
import 'presentation/screens/home_screen.dart';
import '../shared/ui_kit/theme/app_theme.dart';

class PulsoApp extends StatelessWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulso',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OpenedAudioListener(child: HomeScreen()),
    );
  }
}
