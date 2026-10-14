import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/theme/app_colors.dart';
import 'package:pulso/app/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('proporciona fondo principal negro puro #000000', () {
      final theme = AppTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(AppColors.primaryBackground, const Color(0xFF000000));
    });

    test('configura brillo oscuro y Material 3', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
