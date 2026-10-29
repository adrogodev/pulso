# Arquitectura de Pulso

## 1. Visión general
**Pulso** es un reproductor de música nativo para Android diseñado bajo una estética monocromática minimalista (`#000000` / `#FFFFFF` / escala de grises), sin cuentas ni anuncios. La biblioteca local funciona 100% offline; la feature `online_search` añade búsqueda y streaming de música libre desde la API pública de [Audius](https://audius.co) (gratuita, sin clave), reproducible en segundo plano con el mismo motor de audio. La feature `equalizer` aplica un `AndroidEqualizer` dentro del pipeline del reproductor, por lo que afecta tanto a la música local como a la reproducida en línea.

## 2. Paradigma Arquitectónico: Feature-First Clean Architecture

La arquitectura sigue **Feature-First Clean Architecture (FFCA)**: cada feature tiene su propia carpeta con las capas de Clean Architecture (`domain`, `data`, `presentation`), sobre una capa base `shared/` y una capa `app/` que compone las features. Al ser una sola app, el árbol de monorepo propuesto (`apps/`, `shared/`, `features/`) se adapta dentro de `lib/`:

```text
lib/
├── app/                        # Composición de la app (Feature-First Clean Architecture)
│   ├── app.dart                # Widget raíz y MaterialApp
│   └── presentation/
│       └── screens/            # Páginas que componen varias features (HomeScreen)
├── shared/                     # Capa base compartida por todas las features
│   ├── base_domain/
│   │   ├── models/             # Track, Album, Artist, Playlist
│   │   ├── error/              # Fallos tipados (Failure)
│   │   └── result/             # Tipo funcional Result<T>
│   ├── base_data/
│   │   ├── audio/              # AudioPlayerService e implementación JustAudio
│   │   ├── artwork/            # Caché LRU de carátulas de MediaStore
│   │   ├── database/           # DatabaseService (Sqflite y Memory)
│   │   └── permissions/        # PermissionService
│   ├── utils/                  # Utilidades Dart puras (formateadores)
│   └── ui_kit/                 # Design system
│       ├── theme/              # Colores, tipografía y tema Material 3
│       └── widgets/            # Carátula, onda de pulso, diálogo técnico
└── features/
    └── <feature>/              # favorites, library, playback, playlists,
        │                       # online_search, queue, search, settings,
        │                       # equalizer
        ├── domain/
        │   ├── models/         # Modelos propios de la feature
        │   ├── services/       # Contratos (interfaces de repositorio)
        │   └── use_cases/      # Lógica de negocio
        ├── data/
        │   ├── data_sources/
        │   │   ├── local/      # MediaStore, SQLite
        │   │   └── remote/     # APIs HTTP (Audius)
        │   ├── dto/            # Respuestas crudas de APIs remotas
        │   ├── mappers/        # DTO → modelos de dominio
        │   └── services/       # Implementaciones de los contratos
        └── presentation/
            ├── controllers/    # Notifiers y estados de Riverpod
            ├── screens/
            └── widgets/
```

**Regla de dependencias:** `data → domain` y `presentation → domain` dentro de cada feature; las features dependen de `shared/` y, cuando hace falta, de otras features; `app/` compone las features.

### 2.1. Reglas de Dependencias
- **Domain (`shared/base_domain` y `features/*/domain`)**: Modelos, contratos (`services`) y casos de uso. No depende de Flutter UI ni de paquetes de infraestructura o plugins.
- **Data (en cada slice o core)**: Implementa los contratos de repositorio y abstrae SQLite, MediaStore y JustAudio.
- **Presentation**: Se suscribe a Riverpod providers, nunca ejecuta operaciones de I/O directamente ni accede a plugins.
- **Entre features**: Una feature puede depender de `shared/` y de la capa de presentación o dominio de otra feature (por ejemplo, `search` consume el estado de `library`). Las páginas que componen varias features viven en `app/presentation/`.

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
