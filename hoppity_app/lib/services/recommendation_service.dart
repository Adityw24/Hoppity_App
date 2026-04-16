import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';

class RecommendedTour extends Tour {
  final int matchPct;
  final String reasonText;
  final bool isExplore;

  RecommendedTour({
    required super.id,
    required super.title,
    super.description,
    required super.category,
    required super.location,
    super.state,
    required super.durationDisplay,
    required super.pricePerPerson,
    super.maxGroupSize,
    super.difficulty,
    super.highlights,
    super.inclusions,
    super.exclusions,
    super.itineraryDays,
    super.meetingPoint,
    super.languages,
    super.coverImageUrl,
    super.images,
    super.videoUrl,
    super.rating,
    super.reviewCount,
    super.guideId,
    super.guideName,
    super.guideAvatarUrl,
    super.blurb,
    super.route,
    required this.matchPct,
    required this.reasonText,
    this.isExplore = false,
  });

  factory RecommendedTour.fromJson(Map<String, dynamic> json) {
    final base = Tour.fromJson(json);
    return RecommendedTour(
      id: base.id,
      title: base.title,
      description: base.description,
      category: base.category,
      location: base.location,
      state: base.state,
      durationDisplay: base.durationDisplay,
      pricePerPerson: base.pricePerPerson,
      maxGroupSize: base.maxGroupSize,
      difficulty: base.difficulty,
      highlights: base.highlights,
      inclusions: base.inclusions,
      exclusions: base.exclusions,
      itineraryDays: base.itineraryDays,
      meetingPoint: base.meetingPoint,
      languages: base.languages,
      coverImageUrl: base.coverImageUrl,
      images: base.images,
      videoUrl: base.videoUrl,
      rating: base.rating,
      reviewCount: base.reviewCount,
      guideId: base.guideId,
      guideName: base.guideName,
      guideAvatarUrl: base.guideAvatarUrl,
      blurb: base.blurb,
      route: base.route,
      matchPct: (json['match_pct'] as num?)?.toInt() ?? 75,
      reasonText: json['reason_text'] as String? ?? 'Recommended for you',
      isExplore: json['is_explore'] as bool? ?? false,
    );
  }
}

class RecommendationService {
  static final _client = Supabase.instance.client;
  static const _stateKey = 'user_home_state';
  static const _latKey = 'user_lat';
  static const _lngKey = 'user_lng';

  // ── Fetch personalised feed from Edge Function ─────────────────
  static Future<List<RecommendedTour>> fetchForYou({
    bool forceRefresh = false,
    int limit = 20,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) return _fallbackTrending();

    final prefs = await SharedPreferences.getInstance();
    final state = prefs.getString(_stateKey);
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);

    try {
      final res = await _client.functions.invoke(
        'personalize-feed',
        body: {
          'limit': limit,
          'force_refresh': forceRefresh,
          if (state != null) 'state': state,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final list = data['recommendations'] as List<dynamic>? ?? [];
      return list
          .map((j) => RecommendedTour.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallbackTrending();
    }
  }

  // ── Fallback: top-rated tours ──────────────────────────────────
  static Future<List<RecommendedTour>> _fallbackTrending() async {
    try {
      final res = await _client
          .from('Itineraries')
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(20);
      return (res as List)
          .map((j) => RecommendedTour.fromJson({
                ...j,
                'match_pct': 75,
                'reason_text':
                    'One of the most popular tours in India right now.',
              }))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Log a user behaviour event ─────────────────────────────────
  static Future<void> logEvent({
    required String eventType,
    String? tourId,
    String? category,
    String? location,
    int dwellMs = 0,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    _client.from('User_Events').insert({
      'user_id': uid,
      'event_type': eventType,
      if (tourId != null) 'tour_id': int.tryParse(tourId),
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      'dwell_ms': dwellMs,
      if (metadata != null) 'metadata': metadata,
    }).then((_) => _maybeRecomputePrefs(uid));
  }

  static Future<void> _maybeRecomputePrefs(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('event_count_$uid') ?? 0) + 1;
    await prefs.setInt('event_count_$uid', count);
    if (count % 10 == 0) {
      try {
        await _client.rpc('recompute_user_preferences',
            params: {'p_user_id': uid});
      } catch (_) {}
    }
  }

  // ── Mark tours as seen ─────────────────────────────────────────
  static Future<void> markSeen(List<String> tourIds) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || tourIds.isEmpty) return;
    try {
      await _client.rpc('append_seen_tours', params: {
        'p_user_id': uid,
        'p_tour_ids': tourIds.map((id) => int.tryParse(id)).toList(),
      });
    } catch (_) {}
  }

  // ── Request and cache device location ─────────────────────────
  // kIsWeb: browser Geolocation API (HTTPS only, user gesture needed)
  // iOS: requires NSLocation* keys in Info.plist (already added)
  // Android: requires ACCESS_FINE_LOCATION in AndroidManifest (already added)
  static Future<void> requestLocationPermission() async {
    try {
      // Check service availability
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }

      // 5-second timeout — don't block UI on slow GPS acquisition
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            kIsWeb ? LocationAccuracy.low : LocationAccuracy.reduced,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Location timeout'),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lngKey, position.longitude);

      final state =
          _approximateState(position.latitude, position.longitude);
      if (state != null) {
        await prefs.setString(_stateKey, state);
        final uid = _client.auth.currentUser?.id;
        if (uid != null) {
          await _client.from('User_Preferences').upsert({
            'user_id': uid,
            'home_lat': position.latitude,
            'home_lng': position.longitude,
            'home_state': state,
          });
        }
      }
    } catch (_) {
      // Silently fail — app works fine without location
    }
  }

  // ── Save explicit preferences ──────────────────────────────────
  static Future<void> saveExplicitPreferences({
    required List<String> favoriteCategories,
    required double budgetMin,
    required double budgetMax,
    required String preferredDifficulty,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final catScores = {
      for (final cat in favoriteCategories) cat: 80.0,
    };
    await _client.from('User_Preferences').upsert({
      'user_id': uid,
      'category_scores': catScores,
      'price_min': budgetMin,
      'price_max': budgetMax,
      'difficulty_scores': {preferredDifficulty: 80.0},
      'computed_at': DateTime.now().toIso8601String(),
    });
    await _client
        .from('Recommendation_Cache')
        .delete()
        .eq('user_id', uid);
  }

  // ── Rough state approximation from lat/lng ─────────────────────
  static String? _approximateState(double lat, double lng) {
    if (lat > 31.5 && lng > 75.5 && lng < 79.0) return 'Himachal Pradesh';
    if (lat > 29.0 && lat < 31.5 && lng > 77.5) return 'Uttarakhand';
    if (lat > 28.0 && lat < 30.5 && lng > 76.0 && lng < 77.5) return 'Delhi';
    if (lat > 26.5 && lat < 30.0 && lng > 69.5 && lng < 78.0) return 'Rajasthan';
    if (lat > 22.0 && lat < 26.5 && lng > 72.0 && lng < 80.0) return 'Madhya Pradesh';
    if (lat > 15.0 && lat < 20.0 && lng > 73.5 && lng < 75.0) return 'Goa';
    if (lat > 8.0 && lat < 14.0 && lng > 74.5 && lng < 77.5) return 'Kerala';
    if (lat > 12.0 && lat < 15.5 && lng > 76.5 && lng < 80.5) return 'Karnataka';
    if (lat > 17.0 && lat < 22.5 && lng > 76.5 && lng < 81.0) return 'Maharashtra';
    if (lat > 23.0 && lat < 27.5 && lng > 85.0 && lng < 89.0) return 'West Bengal';
    if (lat > 33.0 && lng > 73.5 && lng < 78.0) return 'Jammu & Kashmir';
    return null;
  }
}
