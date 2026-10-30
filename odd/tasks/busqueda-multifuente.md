# Búsqueda en línea multifuente

Objetivo: buscar en varias APIs públicas a la vez (completas + vistas previas) y reproducir desde la app.
Rama: `feat/busqueda-multifuente` · Entrega: ask-on-risk · Tests: `flutter test`.

## Specs

- S1. "Abarca e integra todas las apis publicas de musica en linea para abarcar y buscar las mayor cantidad de musica posible dentro de la App". Fuentes acordadas (L2): Audius, Jamendo, Internet Archive (completas) y Deezer e iTunes (vistas previas de 30 s).
- S2. "un artista reciente es Samu Robles busca sus canciones" — buscar "Samu Robles" devuelve sus canciones y se reproducen en la app.
- S3. "busca todo tipos de musica por ejemplo viejas, recientes, no tan recientes, artistas nuevo".
- S4. "si es necesario integrar varias apis publicas hazlo de manera optima, rapida y eficiente": consultas en paralelo, tiempo límite por fuente, una fuente caída no rompe la búsqueda, sin duplicados.
- S5. Las vistas previas se marcan como tales en la lista (decisión L2).
- S6. Jamendo necesita un `client_id` gratuito: se lee de `--dart-define=JAMENDO_CLIENT_ID`; sin él, la fuente se omite (supuesto).

- S7. "Intenta implemtar la opcion y prueba como se veria dentro de la app": Opción A — buscar con la YouTube Data API v3 (clave por `--dart-define=YOUTUBE_API_KEY`; sin clave, la fuente se omite) y reproducir con el reproductor oficial embebido, visible, en primer plano y con los anuncios de YouTube.

## Tasks

- T1 [S1,S4,S6] Cliente HTTP compartido + fuentes Deezer, iTunes, Jamendo, Internet Archive con tests — inline — done (GREEN, sin commit: L4)
- T2 [S1,S4] Servicio multifuente: paralelo, timeout, deduplicación, orden por relevancia — inline — done (RED→GREEN, sin commit: L4)
- T3 [S5] Marca de vista previa en `Track` y en la lista; textos de la pantalla y docs — inline — done (RED→GREEN, sin commit: L4)
- T4 [S2,S3] Prueba en el teléfono: Samu Robles, música vieja, reciente, artistas nuevos — inline — done (L5)
- T5 [S7] Fuente YouTube Data API v3 (categoría Música, solo embebibles, duración) con tests — inline — done (GREEN; tests escritos junto con el código, sin RED previo)
- T6 [S7] Reproductor oficial embebido: pantalla propia, pausa el motor de Pulso, resultados YouTube fuera de la cola — inline — done (RED→GREEN)
- T7 [S7] Prueba en el teléfono — inline — partial (L8: reproductor real verificado; búsqueda real pendiente de la clave del usuario)
- T8 [S7] Quitar YouTube (L9) — inline — done (161 tests, analyze limpio; reinstalación en el teléfono pendiente: "device offline")

## Log

- L1 (2026-10-30) "Abarca e integra todas las apis publicas de musica en linea para abarcar y buscar las mayor cantidad de musica posible dentro de la App, por ejemplo buscar una de las canciones mas recientes que han salido y reproducelas dentro de la app, un artista reciente es Samu Robles busca sus canciones y busca todo tipos de musica por ejemplo viejas, recientes, no tan recientes, artistas nuevo mejora funcionalidad para abarcar la mayor cantidad de musica posible si es necesario integrar varias apis publicas hazlo de manera optima, rapida y eficiente busca de todo para probar esto y que esta app sea la mejor de busqueda de musica en linea"
- L2 (2026-10-30) Elección del usuario: "Completas + vistas previas (Recomendado)".
- L3 Desde la PC todas las APIs responden 403 (bloqueo de red local); las pruebas reales se hacen en el teléfono.
- L5 Teléfono (SM-A566E, APK release): "Samu Robles" → 8 sencillos 2023-2026 (iTunes); "Trato" suena (00:13/00:30). "Bad Bunny" → sus canciones primero. "boleros 1950" → Internet Archive completas ("LEJOS" suena) + vistas previas sin duplicados. Latencia por fuente 0,2-2,3 s. 164 tests, analyze limpio. Jamendo no probado en vivo (sin client_id).
- L6 (2026-10-30) Corrección del usuario: "la vista previa no es la cancion completa, quitalo y solo deja la musica completa por eso te dije que si podias integrar esta y si no dame otra alternativa pero quiero obtener la musica completa https://ytmusicapi.readthedocs.io/en/stable/ que sea totalmente gratis". S1 y S5 cambian: solo fuentes completas (Audius, Jamendo, Internet Archive); iTunes, Deezer y `Track.isPreview` eliminados. S2 queda sin cumplir: "Samu Robles" ya no da sus canciones (solo un resultado ajeno de Audius). 161 tests, analyze limpio; "LEJOS" (Internet Archive) suena en el teléfono. ytmusicapi no se integra: no entrega audio, y obtenerlo exige extraer el stream de YouTube contra sus términos.
- L7 (2026-10-30) Usuario: "Si agrega embebido de youtube pero solo quiero el audio mp3 nada de video y busca alguna forma o una alternativa para bloquear los anuncios" — rechazado (términos de YouTube). Luego: "Cual es la alternativa recomendada y totalmente gratis?" → Opción A. Luego: "Intenta implemtar la opcion y prueba como se veria dentro de la app".
- L8 Teléfono, con un punto de entrada temporal (borrado) que devolvía un resultado de YouTube de ejemplo (dQw4w9WgXcQ): aparece en la lista como "Rick Astley • YouTube • 2009", abre la pantalla YOUTUBE y el video avanza con el reproductor oficial. La búsqueda real en la YouTube Data API no se probó: falta la clave. 166 tests, analyze limpio.
- L9 (2026-10-30) Usuario: "Puedes por favor lo que es video pasado a mp3 porque es audio la app nada de video pudes" — rechazado (extraer audio de YouTube viola sus condiciones). Luego: "Bueno quita esa parte entonces". S7 queda retirado: se eliminaron la fuente de YouTube, su reproductor, sus tests, la dependencia `youtube_player_iframe` y su documentación.
- L4 Commits pendientes: autor sin definir (adrogodev o andres robles); en el árbol también quedan sin commitear la caché en línea y el arreglo de repetir uno.
