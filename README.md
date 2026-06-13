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

## Release signing (Android)

Play Store uploads must be signed with the upload key. One-time setup:

1. Generate the upload keystore (pick your own passwords; store them in a
   password manager — the keystore and `key.properties` are git-ignored):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:

   ```properties
   storeFile=/Users/<you>/upload-keystore.jks
   storePassword=<store password>
   keyAlias=upload
   keyPassword=<key password>
   ```

3. Build the upload bundle:

   ```bash
   flutter build appbundle --release
   ```

   Output: `build/app/outputs/bundle/release/app-release.aab` — upload this
   in Play Console.

Without `key.properties`, release builds fall back to debug signing so
`flutter run --release` still works, but Play Console will reject them.
Back up the keystore: losing it means resetting the upload key through
Play support.

### Signed builds in CI

The `Release` workflow (`.github/workflows/release.yml`) reconstructs the
keystore from secrets and builds a signed `.aab` + universal `.apk`. It runs
when you push a `v*` tag (and attaches the artifacts to a GitHub Release), or
on demand via **Actions → Release → Run workflow**.

Add these repository secrets once (**Settings → Secrets and variables →
Actions → New repository secret**):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i android/upload-keystore.jks \| pbcopy` (macOS), then paste |
| `ANDROID_KEYSTORE_PASSWORD` | keystore/store password |
| `ANDROID_KEY_PASSWORD` | key password (same as store for PKCS12) |
| `ANDROID_KEY_ALIAS` | `upload` |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | optional runtime config baked in via `--dart-define` |

The build's `versionCode` comes from the workflow run number (kept unique and
monotonic so Play never rejects a duplicate); the `versionName` comes from the
tag (`v1.2.3` → `1.2.3`) or the manual run's input, falling back to `pubspec`.
To cut a release:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

iOS signing in CI is not wired yet (needs Apple certificates + an App Store
Connect API key) — tracked under WOE-056.
