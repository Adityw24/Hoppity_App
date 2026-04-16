# Hoppity — Build & Release Setup

## Prerequisites
- Flutter 3.x (`flutter --version`)
- Xcode 15+ (macOS only, for iOS)
- Android Studio / SDK (compileSdk 35)
- Apple Developer Account ($99/year)
- Google Play Console Account ($25 one-time)

---

## 1. Get dependencies
```bash
flutter pub get
```

---

## 2. App icon (do this FIRST — both stores require it)

Replace `assets/images/app_icon.png` with your 1024×1024 PNG brand icon.
Then generate all sizes:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 3. Android signing keystore

```bash
# Generate once — store the .jks file safely (NOT in git)
keytool -genkey -v -keystore hoppity-release.jks \
  -alias hoppity -keyalg RSA -keysize 2048 -validity 10000

# Copy the template and fill in your values
cp android/key.properties.template android/key.properties
# Edit android/key.properties with your keystore path and passwords
```

---

## 4. Android: local.properties

```bash
cp android/local.properties.template android/local.properties
# Edit android/local.properties:
#   sdk.dir = /Users/yourname/Library/Android/sdk
#   flutter.sdk = /Users/yourname/flutter
```

---

## 5. Google Sign-In setup (critical for OAuth)

1. Go to console.cloud.google.com → APIs & Services → Credentials
2. Create OAuth 2.0 Client ID:
   - **Android**: Package `in.hoppity.app` + SHA-1 fingerprint from keystore
     ```bash
     keytool -list -v -keystore hoppity-release.jks -alias hoppity
     ```
   - **iOS**: Bundle ID `in.hoppity.app`
3. Download `google-services.json` → place in `android/app/`
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. In Supabase Dashboard → Auth → Providers → Google:
   - Add OAuth client ID + secret
   - Add redirect URL: `io.supabase.hoppity://login-callback`
   - Add redirect URL: `https://wenhudcyvlhilpgazylg.supabase.co/auth/v1/callback`

---

## 6. iOS: Xcode setup

```bash
cd ios && pod install && cd ..
```

Open `ios/Runner.xcworkspace` in Xcode:
1. Select Runner target → Signing & Capabilities
2. Set **Bundle Identifier**: `in.hoppity.app`
3. Select your **Team** (Apple Developer account)
4. Enable **Automatically manage signing**
5. Xcode will create provisioning profiles automatically

---

## 7. Build for release

**Android (App Bundle for Play Store):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Android (APK for testing):**
```bash
flutter build apk --release --split-per-abi
```

**iOS (Archive for App Store):**
```bash
flutter build ios --release
# Then in Xcode: Product → Archive → Distribute App
```

---

## 8. Store listings

### Google Play Console
- Package name: `in.hoppity.app`
- Category: Travel & Local
- Content rating: Everyone
- Upload AAB from step 7
- Required assets:
  - Feature graphic: 1024×500px
  - Screenshots: min 2 at 16:9, min 1080px tall
  - Short description: 80 chars max
  - Full description: 4000 chars max

### App Store Connect
- Bundle ID: `in.hoppity.app`
- SKU: `hoppity-india-tours`
- Category: Travel
- Age rating: 4+
- Privacy Policy URL: `https://hoppity.in/privacy` (must be live)
- Required screenshots:
  - 6.7" iPhone (1290×2796) — minimum required
  - 12.9" iPad (2048×2732) — optional but recommended

---

## 9. Privacy Policy
Both stores require a live privacy policy URL.
Create `hoppity.in/privacy` with at minimum:
- What data you collect (location, email, profile photos)
- How you use it (personalisation, bookings)
- Third parties (Supabase, Google Sign-In)
- Contact email for data requests

---

## 10. Supabase production checklist
- [ ] Enable email confirmations in Auth settings
- [ ] Set rate limits (Auth → Rate Limits)
- [ ] Upgrade to Pro plan before launch (free tier has 500MB DB limit)
- [ ] Enable Point-in-Time Recovery (PITR) for backups
- [ ] Set Supabase project region to ap-south-1 (Mumbai) ✅ already done

---

## Environment variables (optional — defaults already in main.dart)
```bash
# Pass at build time to override hardcoded defaults:
flutter build appbundle \
  --dart-define=SUPABASE_URL=https://wenhudcyvlhilpgazylg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

---

## Quick test commands
```bash
flutter analyze          # static analysis
flutter test             # unit tests
flutter run --release    # release mode on connected device
```
