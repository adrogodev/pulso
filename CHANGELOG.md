# Changelog

Todos los cambios relevantes de Pulso se documentan en este archivo.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa [Versionado Semántico](https://semver.org/lang/es/).

## [0.0.1] - 2026-11-04

Primera versión publicada.

### Agregado

- Biblioteca local: canciones, álbumes y artistas del teléfono, con orden configurable y opción para ocultar notas de voz.
- Reproducción en segundo plano con notificación, controles de auriculares, aleatorio, repetir y ecualizador.
- Cola de reproducción editable: reordenar, quitar, "Reproducir a continuación" y "Añadir a la cola".
- Al vaciar la cola, se arma solo con lo que se va escuchando y se conserva al reabrir la app; "Reproducir todo" crea una cola nueva.
- Tocar en una lista la canción que está sonando abre el reproductor en lugar de reiniciarla.
- Favoritos y listas de reproducción, también desde el reproductor con "Añadir a una lista".
- Búsqueda en la biblioteca local.
- Música en línea con la API de Rythmx: canciones completas del catálogo de YouTube Music, con caché en la app de hasta 500 MB.
- "Abrir con Pulso": reproducir cualquier audio desde Archivos, Descargas, WhatsApp o Telegram mediante "Abrir con" o "Compartir".
- Restauración de la última sesión al abrir la app.

### Instalación

- APK universal para cualquier teléfono Android 7.0 o superior (`arm64-v8a`, `armeabi-v7a`, `x86_64`): [`releases/pulso-v0.0.1.apk`](releases/pulso-v0.0.1.apk?raw=true).
- Firmado con la clave de publicación de Pulso. Si tienes instalada una versión de prueba anterior, desinstálala antes, porque estaba firmada con otra clave.

[0.0.1]: https://github.com/adrogodev/pulso/releases/tag/v0.0.1
