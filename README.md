# Pulso — Reproductor Musical para Android

<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="128" height="128" alt="Pulso Logo" />
</p>

<p align="center">
  <strong>Aplicación de reproducción musical nativa, minimalista y moderna para Android: tu biblioteca local offline y música libre en línea vía Audius, gratis y sin anuncios.</strong>
</p>

<p align="center">
  Diseñada con <em>Feature-First Clean Architecture</em> (FFCA), paleta monocromática estricta (<code>#000000</code> / <code>#FFFFFF</code>) y rendimiento optimizado para dispositivos móviles.
</p>

---

## Descargar

<p align="center">
  <a href="releases/pulso-v1.0.0-arm64-v8a.apk?raw=true"><strong>⬇️ Descargar Pulso v1.0.0 (APK, 19,1 MB)</strong></a>
</p>

| Dato | Valor |
| :--- | :--- |
| Archivo | [`releases/pulso-v1.0.0-arm64-v8a.apk`](releases/pulso-v1.0.0-arm64-v8a.apk?raw=true) |
| Versión | 1.0.0 |
| Arquitectura | `arm64-v8a` (prácticamente todos los teléfonos Android de los últimos años) |
| Requisito | Android 5.0 o superior |
| SHA-256 | `52feb91afdf965e401e154ceb94dbd11a68352521086d77c6511f71c28160b91` |

**Instalación:**

1. Descarga el APK en el teléfono.
2. Ábrelo y, si Android lo pide, permite instalar aplicaciones de orígenes desconocidos para tu navegador o gestor de archivos.
3. Al abrir Pulso por primera vez, concede el permiso de acceso a la música.

> El APK está firmado con una clave de desarrollo, no se distribuye por Google Play. Para otras arquitecturas (`armeabi-v7a`, `x86_64`), compílalo con `flutter build apk --release --split-per-abi` (sección 5.4).

---

## 1. Identidad Visual y Experiencia de Usuario

Pulso se aleja intencionadamente de la apariencia estándar de las plantillas móviles para ofrecer una experiencia premium y refinada:

* **Paleta monocromática pura:**
  * Fondo principal absoluto: `#000000` (optimizado para pantallas OLED).
  * Fondo secundario: `#0A0A0A`.
  * Superficies base y elevadas: `#151515` y `#202020`.
  * Bordes y separadores sutiles: `#303030` y `#262626`.
  * Texto y acento principal: `#FFFFFF`.
  * Texto secundario y metadatos: `#A0A0A0`.
* **Iconografía e icono personalizado:**
  * Icono de launcher adaptativo y vectorial con fondo negro y pulso geométrico en blanco puro.
  * Logotipo dinámico con onda de pulso animada durante la reproducción.
* **Tipografía estructurada:** Jerarquía visual clara con pesos variables y tamaños legibles.
* **Componentes interactivos:** Mini reproductor acoplado persistente, barra de progreso interactiva, controles sincronizados con el estado del motor de audio y diálogos de información técnica.

---

## 2. Arquitectura de Software

La aplicación implementa **Feature-First Clean Architecture (FFCA)**: cada feature contiene sus propias capas de Clean Architecture (`domain`, `data`, `presentation`), con una capa base `shared/` y una capa `app/` que compone las features:

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

### Justificación de Dependencias

| Dependencia | Versión | Justificación Técnica |
| :--- | :--- | :--- |
| `flutter_riverpod` | `^3.4.3` | Gestión reactiva del estado sin acoplamiento a widgets. Utiliza `Notifier` y `NotifierProvider` modernos, facilitando pruebas unitarias sin mocks complejos. |
| `just_audio` | `^0.10.6` | Motor de audio nativo de alto rendimiento para Android, con soporte de buffer, control de velocidad, bucle, aleatorio y bajo consumo de batería. |
| `just_audio_background` | `^0.0.1-beta.17` | Integración con `audio_service` de Android para `ForegroundService`, notificaciones multimedia del sistema y control con auriculares/Bluetooth. |
| `audio_session` | `^0.2.4` | Gestión de interrupciones de audio en Android (llamadas telefónicas y desconexión de auriculares `becoming noisy`). |
| `on_audio_query` | `^2.9.0` | Consulta eficiente de metadatos musicales indexados en el `MediaStore` de Android y extracción de carátulas nativas. |
| `permission_handler` | `^13.0.2` | Manejo de permisos adaptativos para Android 13+ (`READ_MEDIA_AUDIO`) y versiones anteriores (`READ_EXTERNAL_STORAGE`). |
| `sqflite` | `^2.4.4+2` | Persistencia relacional local en SQLite para listas de reproducción, favoritos y preferencias de usuario. |
| `path_provider` & `path` | `^2.1.6` / `^1.9.1` | Localización segura de bases de datos y manipulación de rutas en el sistema de archivos. |
| `uuid` | `^4.6.0` | Generación de identificadores únicos estables para listas de reproducción y sesiones. |
| `mocktail` | `^1.0.5` | Creación de mocks sin generación de código para las pruebas automatizadas. |

---

## 3. Estado de Funcionalidades

### Funcionalidades Implementadas

- [x] **Exploración de Biblioteca:**
  - Indexación de canciones locales mediante Android `MediaStore`, con solicitud del permiso de audio al primer uso.
  - Detección de títulos, artistas, álbumes, duraciones, tamaños de archivo y años.
  - Filtro opcional que oculta notas de voz y audios de menos de un minuto sin artista (por ejemplo, los de WhatsApp).
  - Vistas dedicadas para Canciones, Álbumes y Artistas con navegación en detalle.
  - Ordenación de canciones por Título, Artista, Álbum o Duración (Ascendente / Descendente).
- [x] **Motor de Reproducción:**
  - Reproducir, pausar, siguiente, anterior y desplazamiento temporal interactivo (`seek`).
  - Modo aleatorio (`shuffle`) y modos de repetición (`off`, `all`, `one`).
  - Control de volumen del reproductor.
  - Pantalla de reproductor expandido con carátula a gran escala, controles completos y acceso a la cola.
- [x] **Cola de Reproducción:**
  - Pantalla de gestión de cola interactiva con reordenación manual (`ReorderableListView`).
  - Eliminación de canciones individuales y vaciado de cola.
  - Opciones contextuales: "Reproducir a continuación" y "Añadir a la cola".
- [x] **Listas de Reproducción y Favoritos:**
  - Marcado rápido de canciones favoritas con persistencia local en SQLite.
  - Pantalla de favoritos con filtrado instantáneo.
  - Creación, renombrado y eliminación de listas de reproducción personalizadas.
  - Adición y eliminación de pistas en listas con diálogo interactivo.
- [x] **Búsqueda Integrada:**
  - Búsqueda en tiempo real insensible a mayúsculas, minúsculas y tildes.
  - Filtros por categoría: Todo, Canciones, Álbumes y Artistas.
- [x] **Música en Línea (Audius):**
  - Búsqueda de canciones y artistas en la API pública de [Audius](https://audius.co): gratuita, sin cuenta, sin clave y sin anuncios.
  - Reproducción por streaming con el mismo motor de audio, en segundo plano y con carátula en la notificación.
  - Al elegir una canción se abre la vista En reproducción; la canción actual queda resaltada en los resultados y el mini reproductor permite volver a ella.
- [x] **Ecualizador:**
  - Una barra por cada banda que ofrece el dispositivo (por ejemplo, de 60 Hz a 14 kHz), con activación y restablecimiento a 0 dB.
  - Se aplica a la música local y en línea, y conserva los valores entre sesiones.
- [x] **Segundo Plano y Notificaciones:**
  - Integración nativa con `ForegroundService` (`mediaPlayback`).
  - Notificación multimedia en la barra de estado y pantalla de bloqueo de Android con controles de reproducción.
  - Pausa automática al desconectar auriculares (`becoming noisy`).
- [x] **Detalles Técnicos:**
  - Diálogo de información técnica por pista (formato, tamaño, duración, URI completa y número de pista).
- [x] **Configuración y Preferencias:**
  - Recordar la última sesión: al reabrir, la última canción local aparece en pausa en la misma posición.
  - Ocultar notas de voz, ecualizador y estado del permiso de audio.
  - Información de versión del motor y del sistema.

### Limitaciones Técnicas Conocidas

1. **Formatos de Audio:** Los formatos compatibles dependen de los códecs nativos de Android y del motor ExoPlayer subyacente. Formatos estándar como MP3, AAC, M4A, FLAC, OGG y WAV son totalmente compatibles. Formatos poco comunes o archivos corruptos son manejados con errores controlados sin colapsar la interfaz.
2. **Archivos fuera de MediaStore:** Android restringe el acceso al almacenamiento global mediante *Scoped Storage*. Los archivos colocados en carpetas privadas de otras aplicaciones pueden requerir ser movidos a carpetas estándar (`Music`, `Download`) para ser indexados por MediaStore.
3. **Carátulas de audio incrustadas:** En archivos de audio que carecen de portada incrustada en las etiquetas ID3, Pulso muestra un fallback minimalista basado en su logotipo y onda geométrica monocromática.
4. **Última sesión:** solo se restauran canciones locales; una canción en línea no se puede reconstruir solo con su identificador.
5. **Catálogo en línea:** Audius reúne sobre todo artistas independientes; no incluye el catálogo de los grandes sellos.

---

## 4. Requisitos del Entorno

Para compilar y ejecutar Pulso, asegúrate de contar con el siguiente entorno:

* **Flutter SDK:** 3.24.0 o superior (recomendado Flutter 3.47+).
* **Dart SDK:** 3.5.0 o superior (recomendado Dart 3.13+).
* **Java Development Kit (JDK):** JDK 17 o JDK 21.
* **Android SDK:**
  * `compileSdk`: 37 (o 34+).
  * `minSdk`: 21 (Android 5.0 Lollipop).
  * `targetSdk`: 34 (Android 14).
* **Herramientas de compilación:** Gradle 8.x con Android Gradle Plugin 8.x / 9.x.

---

## 5. Instrucciones de Ejecución y Comandos

Todos los comandos deben ejecutarse desde la raíz del proyecto `pulso/`:

### 5.1. Obtener dependencias
```bash
flutter pub get
```

### 5.2. Análisis estático y formateo
```bash
# Formatear el código fuente
dart format .

# Ejecutar el linter estricto de Flutter
flutter analyze
```

### 5.3. Ejecutar la suite de pruebas automatizadas
```bash
# Ejecutar todas las pruebas (unitarias, repositorios y widgets)
flutter test

# Ejecutar con reporte detallado
flutter test --reporter expanded
```

### 5.4. Compilar el APK para Android
```bash
# Compilar APK de depuración (Debug APK)
flutter build apk --debug

# Compilar APK optimizado para distribución (Release APK)
flutter build apk --release

# Compilar un APK liviano por arquitectura (el publicado en releases/ es arm64-v8a)
flutter build apk --release --split-per-abi
```
El archivo generado se ubicará en:
`build/app/outputs/flutter-apk/app-debug.apk` (o `app-release.apk`).

### 5.5. Ejecutar en dispositivo físico o emulador
```bash
flutter run
```

---

## 6. Permisos en Android y Scoped Storage

Pulso solicita únicamente los permisos indispensables para la lectura de audio local:

| Versión de Android | Permiso Solicitado | Comportamiento del Sistema |
| :--- | :--- | :--- |
| **Android 13+ (API 33+)** | `android.permission.READ_MEDIA_AUDIO` | Acceso granular únicamente a archivos clasificados como audio. No accede a fotos ni videos. |
| **Android 12 y anteriores** | `android.permission.READ_EXTERNAL_STORAGE` | Acceso de lectura al almacenamiento multimedia externo. |
| **Todas las versiones** | `android.permission.FOREGROUND_SERVICE`<br>`android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`<br>`android.permission.WAKE_LOCK` | Permite la reproducción ininterrumpida cuando la aplicación pasa a segundo plano o se apaga la pantalla. |
| **Todas las versiones** | `android.permission.INTERNET` | Búsqueda y streaming de música en línea desde Audius. |

Pulso pide el permiso de audio al abrirse por primera vez. Si el usuario lo rechaza, puede concederlo después desde Ajustes o al reescanear la biblioteca.

---

## 7. Pruebas Automatizadas

El proyecto cuenta con una cobertura integral de pruebas que validan cada capa de la arquitectura:

* **Pruebas Unitarias de Dominio:**
  * `test/shared/base_domain/models/track_test.dart`: Inmutabilidad, validación de formatos admitidos y cálculo de duraciones.
  * `test/features/library/domain/use_cases/sort_tracks_test.dart`: Ordenación ascendente y descendente por título, artista, álbum y duración.
  * `test/shared/ui_kit/theme/theme_test.dart`: Conformidad con la paleta monocromática y configuración Material 3.
  * `test/shared/utils/metadata_formatter_test.dart`: Formateo de duraciones (`mm:ss`, `h:mm:ss`), tamaños (`KB`, `MB`) y pistas.
  * `test/features/search/domain/use_cases/search_library_test.dart`: Búsqueda insensible a mayúsculas, minúsculas y coincidencia en múltiples entidades.
* **Pruebas de Repositorios y Servicios:**
  * `test/features/library/data/services/audio_library_repository_test.dart`: Caché en memoria y filtrado de canciones por álbum.
  * `test/features/favorites/data/services/favorites_repository_test.dart`: Persistencia de favoritos en base de datos.
  * `test/features/playlists/data/services/playlists_repository_test.dart`: CRUD de listas de reproducción y ordenación de pistas.
  * `test/features/settings/data/services/settings_repository_test.dart`: Persistencia y recuperación de preferencias locales.
  * `test/features/playback/presentation/controllers/playback_notifier_test.dart`: Sincronización de estados, control de cola, aleatorio y modos de bucle.
  * `test/features/library/presentation/controllers/library_notifier_test.dart`: Carga de pistas, manejo de errores y actualización de ordenación.
* **Pruebas de Widgets y UI:**
  * `test/app/app_test.dart`: Inicialización de la aplicación y renderizado del título.
  * `test/features/playback/presentation/widgets/player_controls_test.dart`: Renderizado de controles, progreso interactivo e iconos dinámicos.
  * `test/features/playback/presentation/widgets/mini_player_test.dart`: Visibilidad condicional y respuesta al toque.
  * `test/features/queue/presentation/screens/queue_screen_test.dart`: Lista interactiva de cola y estados vacíos.
  * `test/features/search/presentation/screens/search_screen_test.dart`: Filtrado en tiempo real y chips de categoría.
  * `test/features/favorites/presentation/screens/favorites_screen_test.dart`: Renderizado de lista de favoritos y estados vacíos.
  * `test/features/playlists/presentation/screens/playlists_screen_test.dart`: Creación de listas, diálogo modal y contador de canciones.
  * `test/features/settings/presentation/screens/settings_screen_test.dart`: Renderizado de switches y opciones de configuración.
  * `test/app/presentation/screens/home_screen_test.dart`: Cabecera de Pulso, pestañas principales, barra de resumen y acoplamiento de mini reproductor.
  * `test/features/library/presentation/screens/detail_screens_test.dart`: Vistas en detalle de álbum y artista, botones de reproducción y diálogo de información técnica.
  * `test/features/playback/presentation/screens/expanded_player_screen_test.dart`: Favorito y acceso a la cola desde el reproductor expandido.
* **Funcionalidades nuevas:**
  * `test/features/online_search/**`: Servicio de Audius, controlador con descarte de respuestas viejas y pantalla de búsqueda en línea.
  * `test/features/equalizer/**`: Persistencia, reaplicación y reversión de cambios del ecualizador, y su pantalla.
  * `test/features/library/domain/use_cases/filter_music_test.dart`: Filtro de notas de voz y audios cortos sin artista.
  * `test/shared/base_data/artwork/artwork_cache_test.dart`: Caché LRU de carátulas.

**Resultado de la suite de pruebas:**
```text
All tests passed! (134 pruebas exitosas, 0 fallos, 0 errores)
flutter analyze: No issues found!
```

---

## 8. Licencia y Créditos

Desarrollado para el proyecto **Pulso** con arquitectura de alto rendimiento para Android.
Diseño e ingeniería por [adrogodev](https://github.com/adrogodev).
