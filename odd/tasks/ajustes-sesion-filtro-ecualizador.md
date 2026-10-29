Objective: make the Settings screen honest and useful: restore the last session, hide non-music clips, add an equalizer.
Branch: refactor/ffca-rendimiento. Delivery: ask-on-risk, work-unit commits. Test runner: `flutter test` (strict TDD), device checks on Galaxy A56 via adb.

## Specs

- S1. "Recordar última sesión": when enabled, the app saves the current track and position and, on the next launch, shows it in the mini player (paused) at that position. When disabled, nothing is restored.
- S2. Replace the decorative "Reescanear al abrir" switch (the library is already rescanned on every launch) with a filter switch that hides clips shorter than 60 s without a known artist (voice notes, WhatsApp clips). Enabled by default. Measured on the device: hides 236 of 449 audios, keeps the 3 short tracks with a known artist.
- S3. User request, verbatim: "en los ajuste si quiero que agregues una especie de ecualizador". Equalizer reachable from Settings: enable/disable, one slider per band reported by the device, reset to flat. Gains and enabled state persist across restarts and apply to playback (local and online).
- S4. User request, verbatim: "sigue haciendo las pruebas desde la app". Verify S1-S3 on the connected phone.

## Tasks

- T1 [S2] filter in library feature + settings switch — route: inline — status: done — commit 4819dc9
- T2 [S1] last-session persistence and restore — route: inline — status: done — commit 5bc7148
- T3 [S3] equalizer feature (domain/data/presentation) + JustAudioPlayerService audio pipeline — route: delegated writer (context backstop; disjoint surface) — status: done — commit 0f59504
- T4 [S3] wire equalizer into settings and player provider — route: inline — status: done — commit 0f59504
- T5 [S4] device verification of S1-S3 — route: inline — status: done (see L4-L6)

## Log

- L1 (2026-10-29, user): "Continua con lo que me recomiendas y sigue haciendo las pruebas desde la app, pero en los ajuste si quiero que agregues una especie de ecualizador"
- L2: just_audio_background 0.0.1-beta.17 forwards InitRequest (androidAudioEffects) and AndroidEqualizer calls to the platform player, so AndroidEqualizer works through the background layer.
- L4 (device, S2): library 430 -> 213 tracks with the filter on; toggling it off restores 430 live without rescanning.
- L5 (device, S1): track "Aleluya" paused at 02:58/05:54 was restored paused at 02:58 after force-stop + relaunch. Online tracks are not saved (limitation: id alone cannot rebuild them).
- L6 (device, S3): 5 bands 60 Hz-14 kHz; dumpsys media.audio_flinger shows EqualizerBundle Enabled=y in the app session, client pid = app; enabled state and gains (+15/-14.5 dB) survive restart; Restablecer sets 0 dB. Left disabled and flat.
- L3: MediaStore marks 447/449 audios as is_music=1, including 416 in WhatsApp Audio (forwarded songs, not only voice notes), so is_music and folder filters are unusable; duration < 60 s plus unknown artist isolates the noise.
