import 'package:flutter/material.dart';

class PulsoApp extends StatelessWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Pulso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
