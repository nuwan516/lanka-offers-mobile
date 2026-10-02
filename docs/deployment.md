# Mobile App Deployment & Release Guide

## 1. Environment Configurations
Configuration is passed via compile-time `--dart-define` flags. Secrets must never be committed into source code.

### Supported Build Profiles

| Environment | API Base URL | Build Command Flag |
|---|---|---|
| **Production** | `https://api.lanka-offers.me` | `--dart-define=API_BASE_URL=https://api.lanka-offers.me` |
| **Staging** | `https://staging-api.lanka-offers.me` | `--dart-define=API_BASE_URL=https://staging-api.lanka-offers.me` |
| **Local / Dev** | `http://10.0.2.2:3001` (Android Em) / `http://localhost:3001` (iOS Sim) | `--dart-define=API_BASE_URL=http://10.0.2.2:3001` |

---

## 2. Android Build

### Debug Build for Physical Device Testing
```bash
flutter build apk --debug --dart-define=API_BASE_URL=https://api.lanka-offers.me
```

### Release Android App Bundle (AAB) for Google Play Store
Ensure Android signing keys (`upload-keystore.jks` and `key.properties`) are placed securely in developer machines or CI secret stores:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.lanka-offers.me
```
The output bundle will be placed at `build/app/outputs/bundle/release/app-release.aab`.

---

## 3. iOS Build

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://api.lanka-offers.me
```

---

## 4. Verification Checklist Before Release
- [ ] Run `flutter analyze` — must report 0 errors.
- [ ] Run `flutter test` — must pass 100% of test suites.
- [ ] Verify physical device launch and home screen loading.
- [ ] Verify card filtering, search, and nearby map view.
