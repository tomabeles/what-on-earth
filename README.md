# What On Earth?!

Flutter AR app that shows the ISS position overlaid on the live camera feed using CesiumJS in a WebView.

## Local development setup

### Prerequisites

- Flutter 3.27+ (Dart 3.6+)
- Node.js 22 LTS + npm 10+
- Xcode 16+ (iOS builds)
- Android SDK API 31+ (Android builds)

### First-time setup

1. **Build the CesiumJS globe bundle** — this must be done before `flutter run` and whenever JS sources in `web_globe/` change:

   ```bash
   scripts/build_globe.sh
   ```

   The output is written to `assets/globe/` (git-ignored). CI runs this step automatically.

2. **Fetch Flutter dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app:**

   ```bash
   flutter run
   ```

### Environment variables

Runtime configuration is injected at build time via `--dart-define`. Copy `.env.example` and pass the keys as `--dart-define=KEY=VALUE` flags (or use a `--dart-define-from-file` file):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

See `.env.example` for the full list of supported variables and their defaults.

### Useful commands

| Command | Description |
|---|---|
| `scripts/build_globe.sh` | Build CesiumJS bundle → `assets/globe/` |
| `flutter pub get` | Fetch Dart dependencies |
| `flutter analyze` | Static analysis (must be clean) |
| `flutter test` | Run unit + widget tests |
| `flutter build apk --debug` | Debug Android build |
| `flutter build ios --no-codesign --debug` | Debug iOS build |
| `dart run build_runner build` | Run drift + riverpod code generation |
