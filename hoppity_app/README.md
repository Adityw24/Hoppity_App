# Hoppity — Guided Tour Aggregator App

> Discover Real India through guided experiences

## What Hoppity is now
Hoppity aggregates guided tours across India — heritage walks, treks, wildlife safaris, culinary trails, spiritual journeys. The app is a TikTok-style discovery feed of tour content (images now, videos soon), each card linking to a fully bookable guided tour.

## Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Run with credentials
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://wenhudcyvlhilpgazylg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Feed Architecture — Image Now, Video Ready
TourFeedCard._buildMedia() renders CachedNetworkImage today.
When ready for video: swap _buildMedia() with VideoPlayer, use
VisibilityDetector for auto-play on scroll. video_player is already
in pubspec.yaml.

## Screens completed
- [x] Welcome / Splash
- [x] Sign In + Sign Up (Supabase Auth)
- [x] Home — TikTok tour feed + category filter strip
- [x] Explore — full-text search + category grid
- [x] Tour Detail — hero, photos, highlights, itinerary, booking flow
- [x] Community Hub — Discover / Trending / Creators (3 tabs, realtime)
- [ ] Profile
- [ ] My Bookings

## Project structure
```
lib/
  main.dart
  theme/app_theme.dart
  models/tour.dart
  models/community.dart
  services/tour_service.dart
  services/community_service.dart
  services/supabase_service.dart
  screens/welcome_screen.dart
  screens/sign_in_screen.dart
  screens/sign_up_screen.dart
  screens/home_screen.dart
  screens/tour_detail_screen.dart
  screens/community_hub_screen.dart
  widgets/tour_feed_card.dart
  widgets/comments_sheet.dart
```
