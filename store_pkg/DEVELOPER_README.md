# Hoppity — Store Submission Package
## Developer Instructions

---

## PACKAGE CONTENTS

```
hoppity_store_package/
│
├── DEVELOPER_README.md          ← This file
├── ASO_SEO_TEXT.md              ← All App Store / Play Store copy
│
├── master_icon_1024.png         ← Master icon (white on purple, 1024×1024 PNG)
├── preview_rounded.png          ← Preview with rounded corners
│
├── ios/
│   └── AppIcon.appiconset/
│       ├── Contents.json        ← Drop directly into Xcode
│       ├── Icon-1024@1x.png     ← App Store listing icon
│       ├── Icon-60@3x.png       ← 180×180 — iPhone main
│       ├── Icon-60@2x.png       ← 120×120 — iPhone main
│       ├── Icon-40@3x.png       ← 120×120 — Spotlight
│       ├── Icon-40@2x.png       ← 80×80
│       ├── Icon-83.5@2x.png     ← 167×167 — iPad Pro
│       ├── Icon-76@2x.png       ← 152×152 — iPad
│       ├── Icon-76@1x.png       ← 76×76
│       ├── Icon-29@3x.png       ← 87×87 — Settings
│       ├── Icon-29@2x.png       ← 58×58
│       ├── Icon-29@1x.png       ← 29×29
│       ├── Icon-20@3x.png       ← 60×60 — Notifications
│       ├── Icon-20@2x.png       ← 40×40
│       └── Icon-20@1x.png       ← 20×20
│
├── android/
│   ├── play_store_icon.png      ← 512×512 for Play Store listing
│   ├── mipmap-mdpi/
│   │   ├── ic_launcher.png      ← 48×48
│   │   ├── ic_launcher_round.png
│   │   └── ic_launcher_foreground.png
│   ├── mipmap-hdpi/             ← 72×72
│   ├── mipmap-xhdpi/            ← 96×96
│   ├── mipmap-xxhdpi/           ← 144×144
│   └── mipmap-xxxhdpi/          ← 192×192
│
├── flutter_assets/
│   ├── app_icon.png             ← Replace assets/images/app_icon.png
│   └── splash.png               ← Splash screen asset
│
├── screenshots/
│   ├── screenshot_01.png        ← Explore & Browse (1290×2796)
│   ├── screenshot_02.png        ← TikTok Feed (1290×2796)
│   ├── screenshot_03.png        ← Smart Search (1290×2796)
│   ├── screenshot_04.png        ← Booking Flow (1290×2796)
│   ├── screenshot_05.png        ← Profile & Community (1290×2796)
│   └── feature_graphic.png      ← Google Play Feature Graphic (1024×500)
│
└── play_screenshots/
    ├── play_01.png              ← Browse (1920×1080 landscape)
    ├── play_02.png              ← Feed (1920×1080)
    ├── play_03.png              ← Search (1920×1080)
    ├── play_04.png              ← Booking (1920×1080)
    └── play_05.png              ← Profile (1920×1080)
```

---

## STEP 1 — Update Flutter App Icon

1. Copy `flutter_assets/app_icon.png` → `assets/images/app_icon.png`
2. Run from project root:
   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
   This auto-generates all platform icon files from the master.

---

## STEP 2 — iOS (Xcode)

**Option A — Auto (recommended):**
After running `flutter_launcher_icons` above, icons are auto-placed.

**Option B — Manual:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. In the Navigator, find `Runner/Assets.xcassets/AppIcon.appiconset`
3. Delete all existing icons
4. Copy the entire contents of `ios/AppIcon.appiconset/` into that folder
5. The `Contents.json` is already included — Xcode will pick it up automatically

**App Store listing icon:**
Upload `Icon-1024@1x.png` in App Store Connect → App → App Information → App Icon

---

## STEP 3 — Android

**Option A — Auto (recommended):**
After running `flutter_launcher_icons`, icons are auto-placed.

**Option B — Manual:**
Copy each `mipmap-*` folder into `android/app/src/main/res/`

**Play Store listing icon:**
Upload `android/play_store_icon.png` in Google Play Console → Store listing → App icon

---

## STEP 4 — App Store Connect (iOS)

### Required screenshots
Upload `screenshots/screenshot_01.png` through `screenshot_05.png`

These are iPhone 6.7" format (1290×2796) which satisfies:
- iPhone 6.7" (required) ✓
- iPhone 6.5" (use same images — accepted)
- No iPad screenshots required for initial submission

### Upload order (recommended)
1. screenshot_01 — Explore India
2. screenshot_02 — TikTok Feed
3. screenshot_03 — Smart Search
4. screenshot_04 — Booking
5. screenshot_05 — Profile & Community

### Copy & paste from ASO_SEO_TEXT.md
- App Name: `Hoppity: Guided Tours India`
- Subtitle: `Heritage · Trek · Wildlife · Culture`
- Description: See `## APP STORE → Description`
- Keywords: See `## APP STORE → Keywords`

---

## STEP 5 — Google Play Console

### Listing assets
- **Hi-res icon:** `android/play_store_icon.png` (512×512)
- **Feature graphic:** `screenshots/feature_graphic.png` (1024×500)
- **Phone screenshots:** `screenshots/screenshot_01.png` through `screenshot_05.png`
- **Tablet screenshots (optional):** `play_screenshots/play_01.png` through `play_05.png`

### Copy & paste from ASO_SEO_TEXT.md
- App Name: `Hoppity: Guided Tours Across India`
- Short description: See `## GOOGLE PLAY → Short Description`
- Full description: See `## GOOGLE PLAY → Full Description`

### Data safety form answers
| Question | Answer |
|---|---|
| Does app collect data? | Yes |
| Location | Approximate location (optional) |
| Personal info | Email address, Phone number |
| App activity | App interactions, in-app search history |
| Is data shared with third parties? | No (except Supabase as data processor) |
| Is data encrypted in transit? | Yes |
| Can users request deletion? | Yes (via WhatsApp support) |

---

## NOTES FOR DEVELOPER

- **Package name:** `in.hoppity.app`
- **Bundle ID:** `in.hoppity.app`
- **Version:** `1.0.0+1`
- **Min iOS:** 14.0
- **Min Android SDK:** 23 (Android 6.0)
- **Privacy Policy:** Must be live at `https://hoppity.in/privacy` before submission
- **Support URL:** `https://hoppity.in`

