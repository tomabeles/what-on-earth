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

### Running on a physical device

Physical device testing is required for Android WebView transparency (emulator behavior differs from hardware — see TECH_SPEC §3.3).

**Android:**

1. Enable **Developer Options** on the device (Settings → About Phone → tap Build Number 7 times).
2. Enable **USB Debugging** (Settings → Developer Options → USB Debugging).
3. Connect via USB, then confirm the device is listed:
   ```bash
   flutter devices
   ```
4. Run on the device:
   ```bash
   flutter run -d <device-id>
   ```

**iOS:**

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Under **Signing & Capabilities**, select your personal or team development account.
3. Build to the device once from Xcode to install the developer certificate.
4. On the device: Settings → General → VPN & Device Management → trust your developer certificate.
5. Run from the terminal:
   ```bash
   flutter run -d <device-id>
   ```

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
