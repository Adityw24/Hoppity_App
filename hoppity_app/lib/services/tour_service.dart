import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';

class TourService {
  static final _client = Supabase.instance.client;

  // ── Feed — active tours with guide info ──────────────────────
  static Future<List<Tour>> fetchTours({
    String? category,
    String? location,
    int limit = 40,
    int offset = 0,
  }) async {
    // Try with Host_details join first; fall back to plain select if join fails
    for (final sel in [
      '*, Host_details(display_name, host_name, avatar_url)',
      '*',
    ]) {
      try {
        var query = _client.from('Itineraries').select(sel);

        if (category != null && category != 'All') {
          query = query.eq('category', category);
        }
        if (location != null && location.isNotEmpty) {
          query = query.ilike('location', '%$location%');
        }

        final res = await query
            .order('rating', ascending: false)
            .range(offset, offset + limit - 1);

        final list = res as List;
        debugPrint('[TourService] fetchTours returned ${list.length} rows (select: $sel)');
        if (list.isNotEmpty) debugPrint('[TourService] sample keys: ${(list.first as Map).keys.toList()}');
        return list.map((j) => Tour.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('[TourService] fetchTours attempt failed ($sel): $e');
        if (sel == '*') return []; // both attempts failed
      }
    }
    return [];
  }

  // ── Single tour detail ─────────────────────────────────────
  static Future<Tour?> fetchTour(String id) async {
    final res = await _client
        .from('Itineraries')
        .select('*, Host_details(display_name, host_name, avatar_url, bio, rating, years_experience, languages_spoken, is_verified)')
        .eq('id', id)
        .single();
    return Tour.fromJson(res);
  }

  // ── Search tours via FTS RPC (falls back to ilike) ─────────
  static Future<List<Tour>> searchTours(String query, {
    String? category, String? state, String? difficulty,
    double? minPrice, double? maxPrice, int limit = 40,
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
        'p_offset':     0,
      });
      return (res as List).map((j) => Tour.fromJson(j as Map<String,dynamic>)).toList();
    } catch (_) {
      // Hard fallback: simple ilike without join
      try {
        final res = await _client
            .from('Itineraries')
            .select('*')
            .or('title.ilike.%$query%,location.ilike.%$query%,blurb.ilike.%$query%')
            .limit(limit);
        return (res as List).map((j) => Tour.fromJson(j as Map<String,dynamic>)).toList();
      } catch (e) {
        debugPrint('[TourService] searchTours fallback ERROR: $e');
        return [];
      }
    }
  }

  // ── Tour feed from Reels (media linked to tours) ───────────
  static Future<List<Map<String, dynamic>>> fetchTourReels({int limit = 20, int offset = 0}) async {
    final res = await _client
        .from('Reels')
        .select('*, Itineraries(id, title, category, location, price_per_person, cover_image_url, rating, difficulty, duration_display)')
        .not('tour_id', 'is', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ── Book a tour (direct confirm — used for free/on-request tours) ─
  static Future<String?> bookTour({
    required String tourId,
    required int numPersons,
    required double totalAmount,
    String? scheduleId,
    DateTime? bookingDate,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final res = await _client.from('Bookings').insert({
      'user_id': uid,
      'tour_id': int.tryParse(tourId),
      'schedule_id': scheduleId,
      'total_amount': totalAmount,
      'num_persons': numPersons,
      'booking_date': bookingDate?.toIso8601String(),
      'status': 'confirmed',
    }).select('id').single();
    return res['id'] as String?;
  }

  // ── Create a pending booking (used before Razorpay QR payment) ─
  /// Inserts the booking with status='pending' and returns its UUID.
  /// The status is promoted to 'confirmed' by the razorpay-webhook Edge Function
  /// once the user pays via the displayed QR code.
  static Future<String?> bookTourPending({
    required String tourId,
    required int numPersons,
    required double totalAmount,
    String? scheduleId,
    DateTime? bookingDate,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final res = await _client.from('Bookings').insert({
      'user_id': uid,
      'tour_id': int.tryParse(tourId),
      'schedule_id': scheduleId,
      'total_amount': totalAmount,
      'num_persons': numPersons,
      'booking_date': bookingDate?.toIso8601String(),
      'status': 'pending',
    }).select('id').single();
    return res['id'] as String?;
  }

  // ── User's bookings ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('Bookings')
        .select('*, Itineraries(title, cover_image_url, category, location, duration_display)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ── Reviews ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchReviews(String tourId) async {
    final res = await _client
        .from('Tour_Reviews')
        .select('*, Users(username, profile_pic)')
        .eq('tour_id', tourId)
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<void> submitReview({
    required String tourId,
    required int rating,
    required String text,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('Tour_Reviews').upsert({
      'tour_id': int.tryParse(tourId),
      'user_id': uid,
      'rating': rating,
      'review_text': text,
    });
  }

  // ── Available tour categories ──────────────────────────────
  static const List<String> categories = [
    'All', 'Heritage', 'Trekking', 'Adventure', 'Wildlife', 'Culinary', 'Spiritual', 'Cultural',
  ];

  // ── Realtime subscription ──────────────────────────────────
  static RealtimeChannel subscribeToNewTours(void Function(Map<String, dynamic>) onInsert) {
    return _client
        .channel('public:Itineraries')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Itineraries',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }
}
