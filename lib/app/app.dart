import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../widgets/ui/pulso_waveform.dart';

class PulsoApp extends StatelessWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulso',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulsoWaveform(width: 80, height: 80),
              SizedBox(height: 16),
              Text(
                'Pulso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
