# Brand artwork sources

Not bundled in the app. These are the sources for the launcher icons and the native splash,
built from the design export's `AppIcon` artwork (orange `#FA7400` box with the ط cut out,
speed lines behind it).

| File | Used for |
|---|---|
| `icon_full.svg/.png` | Launcher icon, full-bleed square (Android legacy, iOS); the platform applies the mask |
| `icon_foreground.svg/.png` | Android adaptive-icon foreground (background colour `#FA7400`) |
| `splash_mark*.svg/.png` | Native splash: white mark on orange (light), orange mark on `#1C1714` (dark), padded for the Android 12 circle |

PNGs were rendered from the SVGs with headless Chrome. To regenerate the platform files after
changing them:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
