import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';

// Platform-agnostic file abstraction
// On mobile: wrap dart:io File
// On web: wrap dart:html Blob / Uint8List
class PlatformFile {
  final String name;
  final String mimeType;
  final List<int> bytes;

  const PlatformFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
}

class UserProfile {
  final String userId;
  final String? fullName;
  final String? username;
  final String? email;
  final String? bio;
  final String? location;
  final String? profilePic;
  final DateTime? memberSince;
  final int tripsCount;
  final int reviewsCount;
  final int wishlistCount;
  final double avgRating;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isCreator;
  final bool isGuide;

  UserProfile({
    required this.userId,
    this.fullName,
    this.username,
    this.email,
    this.bio,
    this.location,
    this.profilePic,
    this.memberSince,
    this.tripsCount = 0,
    this.reviewsCount = 0,
    this.wishlistCount = 0,
    this.avgRating = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isCreator = false,
    this.isGuide = false,
  });

  String get displayName => fullName ?? username ?? 'Traveller';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String? ?? json['description'] as String?,
      location: json['location'] as String?,
      profilePic: json['profile_pic'] as String?,
      memberSince: json['member_since'] != null
          ? DateTime.tryParse(json['member_since'] as String)
          : null,
      tripsCount: (json['trips_count'] as num?)?.toInt() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      wishlistCount: (json['wishlist_count'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      isCreator: json['is_creator'] as bool? ?? false,
      isGuide: json['is_guide'] as bool? ?? false,
    );
  }
}

class UserReview {
  final String id;
  final String tourId;
  final String tourTitle;
  final String? tourImage;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;

  UserReview({
    required this.id,
    required this.tourId,
    required this.tourTitle,
    this.tourImage,
    required this.rating,
    this.reviewText,
    required this.createdAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    final tour = json['Itineraries'] as Map<String, dynamic>?;
    return UserReview(
      id: json['id'] as String,
      tourId: json['tour_id'].toString(),
      tourTitle: tour?['title'] as String? ?? 'Tour',
      tourImage: tour?['cover_image_url'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ProfileService {
  static final _client = Supabase.instance.client;

  // ── Fetch current user's profile ───────────────────────────
  static Future<UserProfile?> fetchMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await _client
          .from('Users')
          .select()
          .eq('user_id', uid)
          .single();
      return UserProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  // ── Fetch any user's profile ───────────────────────────────
  static Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final res = await _client
          .from('Users')
          .select()
          .eq('user_id', userId)
          .single();
      return UserProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  // ── Update profile fields ──────────────────────────────────
  static Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? location,
    String? profilePicUrl,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (location != null) updates['location'] = location;
    if (profilePicUrl != null) updates['profile_pic'] = profilePicUrl;
    if (updates.isEmpty) return;
    await _client.from('Users').update(updates).eq('user_id', uid);
  }

  // ── Upload avatar — platform-agnostic via PlatformFile ─────
  // Caller is responsible for picking the file and converting to bytes.
  // Use image_picker on mobile, dart:html FileReader on web.
  static Future<String?> uploadAvatar(PlatformFile file) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final path = 'profile pic/$uid.${file.name.split('.').last}';
      await _client.storage.from('user').uploadBinary(
            path,
            file.bytes as dynamic,
            fileOptions: FileOptions(
              contentType: file.mimeType,
              upsert: true,
            ),
          );
      return _client.storage.from('user').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  // ── My content (Reels/posts) ───────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchMyContent() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('Reels')
        .select('id, image_url, video_url, caption, likes_count, tour_id')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ── Saved tours (wishlist) — uses tour_id bigint column ──────
  static Future<List<Tour>> fetchSavedTours() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      // Fetch saved tour IDs then load the full tours
      final savesRes = await _client
          .from('Property_Saves')
          .select('tour_id')
          .eq('user_id', uid)
          .not('tour_id', 'is', null)
          .order('created_at', ascending: false);
      final ids = (savesRes as List)
          .map((j) => j['tour_id'])
          .where((id) => id != null)
          .toList();
      if (ids.isEmpty) return [];
      final toursRes = await _client
          .from('Itineraries')
          .select('*, Host_details(display_name, host_name, avatar_url)')
          .inFilter('id', ids)
          .eq('is_active', true);
      return (toursRes as List).map((j) => Tour.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Save a tour (add to wishlist) ─────────────────────────────
  static Future<bool> saveTour(String tourId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      await _client.from('Property_Saves').insert({
        'user_id': uid,
        'tour_id': int.tryParse(tourId),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Unsave a tour (remove from wishlist) ──────────────────────
  static Future<bool> unsaveTour(String tourId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      await _client
          .from('Property_Saves')
          .delete()
          .eq('user_id', uid)
          .eq('tour_id', int.tryParse(tourId) ?? 0);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Check if a tour is saved ───────────────────────────────────
  static Future<bool> isTourSaved(String tourId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final res = await _client
          .from('Property_Saves')
          .select('id')
          .eq('user_id', uid)
          .eq('tour_id', int.tryParse(tourId) ?? 0)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  // ── Past bookings (trips) ─────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchMyTrips() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('Bookings')
        .select(
            '*, Itineraries(id, title, cover_image_url, category, location, duration_display, price_per_person)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ── Reviews written ────────────────────────────────────────
  static Future<List<UserReview>> fetchMyReviews() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('Tour_Reviews')
        .select('*, Itineraries(title, cover_image_url)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).map((j) => UserReview.fromJson(j)).toList();
  }

  // ── Sign out ──────────────────────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
