import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community.dart';

class CommunityService {
  static final _client = Supabase.instance.client;

  // ── Discover feed ──────────────────────────────────────────────
  static Future<List<Post>> fetchPosts({int limit = 20, int offset = 0}) async {
    final res = await _client
        .from('Reels')
        .select('*, Users(username, profile_pic)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (res as List).map((j) => Post.fromJson(j)).toList();
  }

  // ── Like / Unlike ──────────────────────────────────────────────
  static Future<void> likePost(String postId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('Reel_Likes').insert({'user_id': uid, 'reel_id': postId});
    await _client.rpc('increment_reel_likes', params: {'reel_id': postId});
  }

  static Future<void> unlikePost(String postId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('Reel_Likes')
        .delete()
        .eq('user_id', uid)
        .eq('reel_id', postId);
    await _client.rpc('decrement_reel_likes', params: {'reel_id': postId});
  }

  static Future<Set<String>> fetchLikedPostIds(List<String> postIds) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final res = await _client
        .from('Reel_Likes')
        .select('reel_id')
        .eq('user_id', uid)
        .inFilter('reel_id', postIds);
    return (res as List).map((j) => j['reel_id'] as String).toSet();
  }

  // ── Comments ───────────────────────────────────────────────────
  static Future<List<PostComment>> fetchComments(String postId) async {
    final res = await _client
        .from('Post_Comments')
        .select('*, Users(username, profile_pic)')
        .eq('reel_id', postId)
        .order('created_at', ascending: true);
    return (res as List).map((j) => PostComment.fromJson(j)).toList();
  }

  static Future<void> addComment(String postId, String content) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('Post_Comments').insert({
      'reel_id': postId,
      'user_id': uid,
      'content': content,
    });
    await _client.rpc('increment_reel_comments', params: {'reel_id': postId});
  }

  // ── Create post ────────────────────────────────────────────────
  static Future<void> createPost({
    required String imageUrl,
    required String caption,
    required String location,
    required List<String> hashtags,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('Reels').insert({
      'user_id': uid,
      'image_url': imageUrl,
      'caption': caption,
      'location': location,
      'hashtags': hashtags,
      'linked_type': 'community',
    });
  }

  // ── Follow / Unfollow ──────────────────────────────────────────
  static Future<void> followUser(String targetUserId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('Follows').insert({
      'follower_id': uid,
      'following_id': targetUserId,
    });
  }

  static Future<void> unfollowUser(String targetUserId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('Follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', targetUserId);
  }

  static Future<Set<String>> fetchFollowingIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final res = await _client
        .from('Follows')
        .select('following_id')
        .eq('follower_id', uid);
    return (res as List).map((j) => j['following_id'] as String).toSet();
  }

  // ── Trending Destinations ──────────────────────────────────────
  static Future<List<TrendingDestination>> fetchTrending() async {
    final res = await _client
        .from('Trending_Destinations')
        .select()
        .order('trending_percent', ascending: false);
    return (res as List).map((j) => TrendingDestination.fromJson(j)).toList();
  }

  // ── Featured Creators ──────────────────────────────────────────
  static Future<List<Creator>> fetchCreators() async {
    final res = await _client
        .from('Users')
        .select()
        .eq('is_creator', true)
        .order('followers_count', ascending: false)
        .limit(20);
    return (res as List).map((j) => Creator.fromJson(j)).toList();
  }

  // ── Realtime subscription ──────────────────────────────────────
  static RealtimeChannel subscribeToPosts(
    void Function(Map<String, dynamic>) onInsert,
  ) {
    return _client
        .channel('public:Reels')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Reels',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }
}
