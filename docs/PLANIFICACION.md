# Planificación del Proyecto Pulso

## 1. Objetivos del Sistema
Pulso es un reproductor de música local offline para Android con estética monocromática minimalista, arquitectura robusta (FSD + Clean Architecture), persistencia local en SQLite y control multimedia en primer y segundo plano.

## 2. Decisiones Técnicas Confirmadas
- **Framework & SDK**: Flutter 3.47+ / Dart 3.13+.
- **Plataforma Objetivo**: Android (API 21 a 34+ con soporte para Scoped Storage y permisos de audio en Android 13+ `READ_MEDIA_AUDIO`).
- **Arquitectura**: Feature-Sliced Design (FSD) combinado con Clean Architecture e Inversión de Dependencias.
- **Gestión de Estado**: `flutter_riverpod` para reactividad predecible, testing sin acoplamiento y control de ciclo de vida.
- **Reproducción de Audio**: `just_audio` con `just_audio_background` (`audio_service`) para Foreground Service y controles del sistema.
- **Indexación de Medios**: MediaStore mediante `on_audio_query` con manejo explícito de permisos y fallbacks.
- **Persistencia**: SQLite mediante `sqflite` con base de datos relacional para favoritos, listas y ordenación de pistas.
- **Navegación**: `go_router` con ShellRoute para mini reproductor global persistente.
- **Estilo Visual**: Monocromático estricto (fondo `#000000`, tarjetas y modales `#151515`/`#202020`, divisores `#303030`, texto `#FFFFFF` y `#A0A0A0`).

## 3. Fases de Implementación
1. **Fase 1: Inspección y Planificación**: Inspección de herramientas, definición de arquitectura y commits atómicos.
2. **Fase 2: Fundamentos**: Configuración de dependencias, análisis estático, tokens de diseño y creación del icono de la aplicación.
3. **Fase 3: Dominio**: Modelos de entidades inmutables (`Track`, `Album`, `Artist`, `Playlist`), contratos de repositorios y casos de uso.
4. **Fase 4: Biblioteca Local**: Permisos, escaneo de MediaStore, extracción de metadatos y detección de formatos (MP3, AAC, M4A, FLAC, WAV, OGG).
5. **Fase 5: Motor de Reproducción**: Integración de `just_audio`, sincronización de estados, control de cola, repetición y aleatorio.
6. **Fase 6: Funcionalidades de Biblioteca**: Búsqueda insensible a mayúsculas/minúsculas, favoritos, gestión de listas de reproducción con persistencia SQLite.
7. **Fase 7: Integración Android y Segundo Plano**: Configuración de `AndroidManifest.xml` (Foreground Service, MediaSession, AudioFocus) e iconos adaptativos.
8. **Fase 8: Calidad, Pruebas y Validación**: Pruebas unitarias de casos de uso, repositorios, widgets, análisis estático (`flutter analyze`), formato y compilación APK.
