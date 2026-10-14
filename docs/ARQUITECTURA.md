# Arquitectura de Pulso

## 1. Visión general
**Pulso** es un reproductor de audio local nativo para Android diseñado bajo una estética monocromática minimalista (`#000000` / `#FFFFFF` / escala de grises), sin dependencias en la nube ni servicios de streaming. Funciona 100% offline y garantiza una experiencia fluida, robusta y con alta fidelidad arquitectónica.

## 2. Paradigma Arquitectónico: FSD + Clean Architecture

La arquitectura combina los principios de **Feature-Sliced Design (FSD)** adaptados a Flutter con **Clean Architecture** e Inversión de Dependencias (SOLID):

```text
lib/
├── app/                  # Nivel superior de la aplicación
│   ├── app.dart          # Configuración del widget raíz y MaterialApp
│   ├── router/           # Enrutamiento declarativo (GoRouter)
│   └── theme/            # Tema monocromático y tokens de diseño
├── core/                 # Utilidades compartidas y abstracciones transversales
│   ├── audio/            # Interfaces de bajo nivel del motor de audio
│   ├── constants/        # Constantes de diseño y configuración
│   ├── error/            # Fallos y excepciones tipadas
│   ├── permissions/      # Servicios de permisos de almacenamiento/audio
│   └── result/           # Patrón Result para retorno funcional de operaciones
├── entities/             # Modelos de dominio puros y reglas de negocio
│   ├── album/            # Entidad Album y valor de objeto
│   ├── artist/           # Entidad Artist
│   ├── playlist/         # Entidad Playlist y entradas de lista
│   └── track/            # Entidad Track (identificador único, metadatos, uri)
├── features/             # Slices funcionales desacoplados
│   ├── library/          # Exploración general, canciones, artistas y álbumes
│   ├── scan_library/     # Escaneo de MediaStore y detección de archivos
│   ├── playback/         # Control del reproductor, sincronización de estado
│   ├── queue/            # Gestión de cola, repetición y modo aleatorio
│   ├── search/           # Búsqueda local sin distinción de mayúsculas/minúsculas
│   ├── favorites/        # Marcado y persistencia de canciones favoritas
│   ├── playlists/        # CRUD de listas, reordenación y asociación de pistas
│   └── settings/         # Preferencias locales y metadatos del sistema
└── widgets/              # Componentes de UI transversales y reutilizables
    ├── mini_player/      # Mini reproductor persistente
    ├── player_controls/  # Botones y barras de progreso del reproductor
    └── ui/               # Botones, diálogos y contenedores monocromáticos
```

### 2.1. Reglas de Dependencias
- **Domain (`entities` / contratos de casos de uso)**: No depende de Flutter UI ni de paquetes de infraestructura o plugins.
- **Data (en cada slice o core)**: Implementa los contratos de repositorio y abstrae SQLite, MediaStore y JustAudio.
- **Presentation**: Se suscribe a Riverpod providers, nunca ejecuta operaciones de I/O directamente ni accede a plugins.
- **FSD isolation**: Las features no deben acoplarse directamente entre sí; interactúan a través de entidades del dominio y providers compartidos.

## 3. Motor de Audio y Segundo Plano
- **Motor principal**: `just_audio` proporcionando control de audio de baja latencia, buffer, eventos de stream y manejo de errores.
- **Segundo Plano**: `just_audio_background` integrado con `audio_service`, configurado en el `AndroidManifest.xml` como un `ForegroundService` de tipo `mediaPlayback`.
- **Notificación multimedia**: Sincronización de título, artista, carátula o fallback monocromático, progreso y controles multimedia (anterior, reproducir/pausar, siguiente).
- **Manejo de interrupciones**: AudioFocus para llamadas entrantes y desconexión de auriculares (`becoming noisy`).

## 4. Persistencia Local
- **Base de datos**: SQLite vía `sqflite`.
- **Tablas**:
  - `favorites`: `track_id` (PRIMARY KEY), `added_at`.
  - `playlists`: `id` (PRIMARY KEY), `name`, `created_at`, `updated_at`.
  - `playlist_tracks`: `playlist_id`, `track_id`, `position`, PRIMARY KEY (`playlist_id`, `position`).
  - `settings`: `key` (PRIMARY KEY), `value`.
  - `playback_history`: `track_id`, `played_at`, `completion_rate`.

## 5. Estrategia de Pruebas
1. **Pruebas unitarias**: Cobertura de entidades, casos de uso, formateadores, ordenación, filtrado y búsqueda.
2. **Pruebas de repositorio**: Dobles de prueba simulando persistencia SQLite y MediaStore.
3. **Pruebas de widgets**: Renderizado con Riverpod ProviderScope, estados vacíos, controles de reproducción y tema.
