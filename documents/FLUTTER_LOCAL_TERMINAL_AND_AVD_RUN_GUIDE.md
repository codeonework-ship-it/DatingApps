# Flutter Local Terminal + AVD Run Guide (Production API)

This guide shows exactly how to launch Android emulator (AVD) and run Flutter from terminal on macOS.

## 1) Open project and move to app

```bash
cd "/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps/app"
```

## 2) Verify toolchain and devices

```bash
flutter doctor -v
flutter emulators
flutter devices
```

From this machine, available AVD was:
- `Medium_Phone_API_36.1`

## 3) Launch AVD from terminal

```bash
flutter emulators --launch Medium_Phone_API_36.1
```

Wait 20-40 seconds, then confirm device:

```bash
flutter devices
```

Expected Android device id:
- `emulator-5554`

## 4) Set runtime environment for production API

Preferred file-based setup in `app/.env.local`:

```dotenv
API_ENV=production
API_PROD_BASE_URL=http://72.61.242.87/v1
API_LOCAL_BASE_URL=http://10.0.2.2:8080/v1
```

Optional hard override:

```dotenv
API_BASE_URL=http://72.61.242.87/v1
```

Config precedence in app:
1. `.env.local` / `.env`
2. `--dart-define`
3. code defaults

## 5) Run Flutter app against production API (terminal)

```bash
flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL=http://72.61.242.87/v1 \
  --dart-define=API_ENV=production \
  --dart-define=USE_MOCK_AUTH=false \
  --dart-define=USE_MOCK_DISCOVERY_DATA=false
```

This command was executed successfully in local testing and app logs showed requests with:
- `"base_url":"http://72.61.242.87/v1"`

## 6) Useful run variations

Run on macOS desktop:

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://72.61.242.87/v1
```

Build debug APK only:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://72.61.242.87/v1
```

Verbose logs:

```bash
flutter run -d emulator-5554 --verbose \
  --dart-define=API_BASE_URL=http://72.61.242.87/v1
```

## 7) Stopping and rerunning

In running `flutter run` terminal:
- press `q` to quit
- press `r` for hot reload
- press `R` for hot restart

Kill app on emulator if needed:

```bash
adb -s emulator-5554 shell am force-stop com.verified_dating.verified_dating_app
```

## 8) AVD troubleshooting

If emulator is not detected:

```bash
flutter emulators
flutter emulators --launch Medium_Phone_API_36.1
adb devices
flutter devices
```

If app still hits local API instead of production:

```bash
grep -E '^API_ENV|^API_BASE_URL|^API_PROD_BASE_URL' .env.local .env 2>/dev/null
```

Then fully stop and rerun `flutter run`.

## 9) API smoke checks from local terminal

```bash
curl -i http://72.61.242.87/healthz
curl -i http://72.61.242.87/readyz
curl -i -X POST http://72.61.242.87/v1/auth/send-otp \
  -H 'Content-Type: application/json' \
  -d '{"email":"smoke@example.com"}'
```

If Flutter gets `502` on terms/profile-specific endpoints, backend is reachable but specific upstream path/storage migration is failing; check VPS backend logs and migration state.
