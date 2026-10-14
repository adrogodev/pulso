import 'package:flutter/material.dart';

/// Paleta de colores oficial y monocromática de Pulso.
abstract final class AppColors {
  /// Fondo principal absoluto (#000000).
  static const Color primaryBackground = Color(0xFF000000);

  /// Fondo secundario para capas y elevaciones (#0A0A0A).
  static const Color secondaryBackground = Color(0xFF0A0A0A);

  /// Superficie base para tarjetas y contenedores (#151515).
  static const Color surface = Color(0xFF151515);

  /// Superficie elevada para diálogos y hojas modales (#202020).
  static const Color surfaceElevated = Color(0xFF202020);

  /// Bordes y separadores divisorios (#303030).
  static const Color border = Color(0xFF303030);

  /// Divisor sutil (#262626).
  static const Color divider = Color(0xFF262626);

  /// Texto principal de alto contraste (#FFFFFF).
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Texto secundario para subtítulos y metadatos (#A0A0A0).
  static const Color textSecondary = Color(0xFFA0A0A0);

  /// Texto y elementos deshabilitados (#606060).
  static const Color textDisabled = Color(0xFF606060);

  /// Acento monocromático activo (blanco puro).
  static const Color accent = Color(0xFFFFFFFF);

  /// Iconografía activa.
  static const Color iconActive = Color(0xFFFFFFFF);

  /// Iconografía inactiva / atenuada.
  static const Color iconMuted = Color(0xFFA0A0A0);

  /// Indicador de error monocromático de alta visibilidad (#E0E0E0 sobre fondo oscuro).
  static const Color error = Color(0xFFE0E0E0);
}
