import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/comments_sheet.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _DiscoverTab(),
                _TrendingTab(),
                _CreatorsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Community Hub',
        style: GoogleFonts.figtree(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.25)),
          bottom: BorderSide(color: Colors.black.withOpacity(0.25)),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      height: 60,
      child: Row(
        children: [
          Expanded(child: _TabChip(label: 'Discover', selected: _selectedTab == 0, onTap: () => _tabController.animateTo(0))),
          Expanded(child: _TabChip(label: 'Trending', selected: _selectedTab == 1, onTap: () => _tabController.animateTo(1))),
          Expanded(child: _TabChip(label: 'Creators', selected: _selectedTab == 2, onTap: () => _tabController.animateTo(2))),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// DISCOVER TAB
// ─────────────────────────────────────────────────────────────────────
class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  List<Post> _posts = [];
  Set<String> _followingIds = {};
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final posts = await CommunityService.fetchPosts();
      final ids = posts.map((p) => p.id).toList();
      final likedIds = await CommunityService.fetchLikedPostIds(ids);
      final followingIds = await CommunityService.fetchFollowingIds();
      if (mounted) {
        setState(() {
          _posts = posts.map((p) => p..isLiked = likedIds.contains(p.id)).toList();
          _followingIds = followingIds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribeRealtime() {
    _channel = CommunityService.subscribeToPosts((record) {
      final post = Post.fromJson(record);
      if (mounted) setState(() => _posts.insert(0, post));
    });
  }

  Future<void> _toggleLike(Post post) async {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
    });
    if (post.isLiked) {
      await CommunityService.likePost(post.id);
    } else {
      await CommunityService.unlikePost(post.id);
    }
  }

  Future<void> _toggleFollow(String userId) async {
    final isFollowing = _followingIds.contains(userId);
    setState(() {
      if (isFollowing) {
        _followingIds.remove(userId);
      } else {
        _followingIds.add(userId);
      }
    });
    if (isFollowing) {
      await CommunityService.unfollowUser(userId);
    } else {
      await CommunityService.followUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No posts yet', style: GoogleFonts.figtree(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _posts.length,
        itemBuilder: (_, i) => _PostCard(
          post: _posts[i],
          isFollowing: _followingIds.contains(_posts[i].userId),
          onLike: () => _toggleLike(_posts[i]),
          onFollow: () => _toggleFollow(_posts[i].userId),
          onComment: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => CommentsSheet(postId: _posts[i].id),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool isFollowing;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onComment;

  const _PostCard({
    required this.post,
    required this.isFollowing,
    required this.onLike,
    required this.onFollow,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar, name, follow button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: post.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(post.authorAvatarUrl!) : null,
                  child: post.authorAvatarUrl == null
                      ? const Icon(Icons.person, size: 20) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorName ?? 'Explorer',
                    style: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                GestureDetector(
                  onTap: onFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.grey[200] : AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isFollowing) ...[
                          const Icon(Icons.person_add, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: GoogleFonts.figtree(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isFollowing ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Caption
          if (post.caption != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                post.caption!,
                style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Post image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 220, color: Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined,
                        size: 40, color: Colors.grey)),
                ),
              ),
            ),
          ],

          // Location
          if (post.location != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.black.withOpacity(0.35)),
                  const SizedBox(width: 4),
                  Text(
                    post.location!,
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Hashtags
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Wrap(
                spacing: 8,
                children: post.hashtags.map((tag) => _HashTag(tag: tag)).toList(),
              ),
            ),
          ],

          // Divider
          const SizedBox(height: 10),
          Divider(color: Colors.black.withOpacity(0.15), height: 1),

          // Actions: likes, comments, share
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _ActionBtn(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  count: post.likesCount,
                  color: post.isLiked ? Colors.red : Colors.black,
                  onTap: onLike,
                ),
                const SizedBox(width: 20),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  count: post.commentsCount,
                  onTap: onComment,
                ),
                const SizedBox(width: 20),
                _ActionBtn(icon: Icons.share_outlined, onTap: () async {
                  final text = Uri.encodeComponent(
                    'Check out this experience on Hoppity! https://hoppity.in'
                  );
                  final uri = Uri.parse('https://wa.me/?text=$text');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HashTag extends StatelessWidget {
  final String tag;
  const _HashTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap, this.count, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text('$count', style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TRENDING TAB
// ─────────────────────────────────────────────────────────────────────
class _TrendingTab extends StatefulWidget {
  const _TrendingTab();

  @override
  State<_TrendingTab> createState() => _TrendingTabState();
}

class _TrendingTabState extends State<_TrendingTab> {
  List<TrendingDestination> _destinations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await CommunityService.fetchTrending();
    if (mounted) setState(() { _destinations = d; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text('Trending Destinations',
            style: GoogleFonts.figtree(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text("Discover what's popular in the travel community",
            style: GoogleFonts.figtree(fontSize: 15, color: Colors.black.withOpacity(0.35))),
        const SizedBox(height: 16),
        ..._destinations.map((d) => _TrendingCard(destination: d)),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final TrendingDestination destination;
  const _TrendingCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: destination.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: destination.imageUrl!,
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 90, height: 90, color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_outlined,
                          size: 32, color: Colors.grey)),
                  )
                : Container(width: 90, height: 90, color: Colors.grey[200]),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(destination.name,
                          style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 2),
                        Text('${destination.rating}',
                            style: GoogleFonts.figtree(fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 10, color: Colors.black.withOpacity(0.5)),
                    const SizedBox(width: 2),
                    Text(destination.location,
                        style: GoogleFonts.figtree(fontSize: 12, color: Colors.black.withOpacity(0.35))),
                  ],
                ),
                const SizedBox(height: 8),
                // Trending badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BF7C).withOpacity(0.36),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${destination.trendingPercent}% Trending',
                    style: GoogleFonts.figtree(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006150)),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${destination.postCount} posts',
                    style: GoogleFonts.figtree(
                        fontSize: 12, color: Colors.black.withOpacity(0.35)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// CREATORS TAB
// ─────────────────────────────────────────────────────────────────────
class _CreatorsTab extends StatefulWidget {
  const _CreatorsTab();

  @override
  State<_CreatorsTab> createState() => _CreatorsTabState();
}

class _CreatorsTabState extends State<_CreatorsTab> {
  List<Creator> _creators = [];
  Set<String> _followingIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final creators = await CommunityService.fetchCreators();
    final followingIds = await CommunityService.fetchFollowingIds();
    if (mounted) {
      setState(() {
        _creators = creators.map((c) => c..isFollowing = followingIds.contains(c.userId)).toList();
        _followingIds = followingIds;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow(Creator creator) async {
    setState(() {
      creator.isFollowing = !creator.isFollowing;
      if (creator.isFollowing) {
        _followingIds.add(creator.userId);
      } else {
        _followingIds.remove(creator.userId);
      }
    });
    if (creator.isFollowing) {
      await CommunityService.followUser(creator.userId);
    } else {
      await CommunityService.unfollowUser(creator.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_creators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No creators yet', style: GoogleFonts.figtree(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text('Featured Creators',
            style: GoogleFonts.figtree(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Follow inspiring travel creators and experts',
            style: GoogleFonts.figtree(fontSize: 15, color: Colors.black.withOpacity(0.35))),
        const SizedBox(height: 16),
        ..._creators.map((c) => _CreatorCard(
              creator: c,
              onFollow: () => _toggleFollow(c),
            )),
      ],
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final Creator creator;
  final VoidCallback onFollow;
  const _CreatorCard({required this.creator, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundImage: creator.avatarUrl != null
                    ? CachedNetworkImageProvider(creator.avatarUrl!) : null,
                child: creator.avatarUrl == null
                    ? const Icon(Icons.person, size: 24) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creator.username,
                        style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(creator.bio ?? 'Travel Creator',
                        style: GoogleFonts.figtree(
                            fontSize: 12, color: Colors.black.withOpacity(0.35))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${_formatCount(creator.followersCount)} followers',
                          style: GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${creator.postsCount} posts',
                          style: GoogleFonts.figtree(
                              fontSize: 11, color: Colors.black.withOpacity(0.35)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final name = Uri.encodeComponent(creator.username);
                    final uri = Uri.parse(
                      'https://wa.me/919752377323?text=Hi%20Hoppity%21%20I%20want%20to%20know%20more%20about%20creator%20$name');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('View Details',
                      style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: creator.isFollowing ? Colors.grey[300] : AppTheme.primary,
                    foregroundColor: creator.isFollowing ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    creator.isFollowing ? 'Following' : 'Follow',
                    style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
