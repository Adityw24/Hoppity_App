import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';

// ── SearchResult extends Tour with a relevance rank ──────────────────
class SearchResult extends Tour {
  final double rank;
  SearchResult({required super.id, required super.title, required super.category,
    required super.location, required super.durationDisplay, required super.pricePerPerson,
    super.description, super.state, super.difficulty, super.highlights, super.inclusions,
    super.exclusions, super.itineraryDays, super.meetingPoint, super.languages,
    super.coverImageUrl, super.images, super.videoUrl, super.rating, super.reviewCount,
    super.guideId, super.guideName, super.guideAvatarUrl, super.blurb, super.route,
    super.maxGroupSize, super.minGroupSize, required this.rank});

  factory SearchResult.fromJson(Map<String, dynamic> j) {
    final base = Tour.fromJson(j);
    return SearchResult(
      id: base.id, title: base.title, category: base.category,
      location: base.location, durationDisplay: base.durationDisplay,
      pricePerPerson: base.pricePerPerson, description: base.description,
      state: base.state, difficulty: base.difficulty, highlights: base.highlights,
      inclusions: base.inclusions, exclusions: base.exclusions,
      itineraryDays: base.itineraryDays, meetingPoint: base.meetingPoint,
      languages: base.languages, coverImageUrl: base.coverImageUrl,
      images: base.images, videoUrl: base.videoUrl, rating: base.rating,
      reviewCount: base.reviewCount, guideId: base.guideId, guideName: base.guideName,
      guideAvatarUrl: base.guideAvatarUrl, blurb: base.blurb, route: base.route,
      maxGroupSize: base.maxGroupSize, minGroupSize: base.minGroupSize,
      rank: (j['rank'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── SearchSuggestion ──────────────────────────────────────────────────
class SearchSuggestion {
  final String label;
  final String type; // 'tour' | 'place' | 'state'
  final String? category;
  const SearchSuggestion({required this.label, required this.type, this.category});

  factory SearchSuggestion.fromJson(Map<String, dynamic> j) => SearchSuggestion(
    label: j['label'] as String,
    type:  j['type']  as String,
    category: j['category'] as String?,
  );
}

class SearchService {
  static final _client = Supabase.instance.client;
  static const _recentKey = 'recent_searches_v1';
  static const _maxRecent = 8;

  // ── Full search via Postgres FTS RPC ──────────────────────────────
  static Future<List<SearchResult>> search({
    String query = '',
    String? category,
    String? state,
    String? difficulty,
    double? minPrice,
    double? maxPrice,
    int limit = 40,
    int offset = 0,
  }) async {
    try {
      final res = await _client.rpc('search_itineraries', params: {
        'p_query':      query.trim(),
        'p_category':   category,
        'p_state':      state,
        'p_difficulty': difficulty,
        'p_min_price':  minPrice,
        'p_max_price':  maxPrice,
        'p_limit':      limit,
        'p_offset':     offset,
      });
      return (res as List).map((j) => SearchResult.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Live suggestions while typing ────────────────────────────────
  static Future<List<SearchSuggestion>> suggestions(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final res = await _client.rpc('search_suggestions', params: {
        'p_query': query.trim(),
        'p_limit': 8,
      });
      return (res as List).map((j) => SearchSuggestion.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Trending searches ─────────────────────────────────────────────
  static Future<List<String>> trending({int limit = 8}) async {
    try {
      final res = await _client
          .from('Search_Trends')
          .select('query')
          .order('count', ascending: false)
          .limit(limit);
      return (res as List).map((j) => j['query'] as String).toList();
    } catch (_) {
      return ['Meghalaya', 'Spiti Valley', 'Ladakh', 'Rajasthan',
               'Kerala', 'Wildlife', 'Heritage', 'Himalayas'];
    }
  }

  // ── Track what was searched ───────────────────────────────────────
  static Future<void> recordSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    // Persist locally
    await _addRecent(q);
    // Increment server trend counter (best-effort, no await)
    try {
      _client.rpc('increment_search_trend', params: {'p_query': q});
    } catch (_) {}
  }

  // ── Recent searches (SharedPreferences) ──────────────────────────
  static Future<List<String>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  static Future<void> _addRecent(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.removeWhere((s) => s.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    if (list.length > _maxRecent) list.removeRange(_maxRecent, list.length);
    await prefs.setStringList(_recentKey, list);
  }

  static Future<void> removeRecent(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.removeWhere((s) => s.toLowerCase() == q.toLowerCase());
    await prefs.setStringList(_recentKey, list);
  }

  static Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }
}
