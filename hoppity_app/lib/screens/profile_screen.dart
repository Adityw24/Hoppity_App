import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tour.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'my_bookings_screen.dart';
import 'tour_detail_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  int _selectedTab = 0; // 0=Overview 1=Saved 2=Trips 3=Reviews

  // Figma: active tab = rgba(123,57,234,0.37)
  static final _tabActiveColor = AppTheme.primary.withOpacity(0.37);

  final _tabs = ['Overview', 'Saved', 'Trips', 'Reviews'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService.fetchMyProfile();
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _loading || _profile == null
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text('Profile',
                  style: GoogleFonts.figtree(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
              actions: [
                IconButton(
                  onPressed: _showSettings,
                  icon: const Icon(Icons.settings_outlined,
                      size: 26, color: Colors.black),
                ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _profile == null
              ? _buildNotSignedIn()
              : NestedScrollView(
                  headerSliverBuilder: (_, __) => [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        tabs: _tabs,
                        selected: _selectedTab,
                        onTap: (i) => setState(() => _selectedTab = i),
                        activeColor: _tabActiveColor,
                      ),
                    ),
                  ],
                  body: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _OverviewTab(profile: _profile!),
                      _SavedTab(),
                      _TripsTab(),
                      _ReviewsTab(),
                    ],
                  ),
                ),
    );
  }

  // ── Scrollable profile info ───────────────────────────────
  Widget _buildHeader() {
    final p = _profile!;
    return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name + location row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Figma: 80px circle avatar
                  GestureDetector(
                    onTap: _editProfile,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: p.profilePic != null
                              ? CachedNetworkImageProvider(p.profilePic!)
                              : null,
                          child: p.profilePic == null
                              ? Text(
                                  p.displayName.isNotEmpty
                                      ? p.displayName[0].toUpperCase()
                                      : 'T',
                                  style: GoogleFonts.figtree(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[600]),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Figma: 24px SemiBold name
                        Text(p.displayName,
                            style: GoogleFonts.figtree(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        const SizedBox(height: 4),

                        // Figma: pin icon + location text rgba(0,0,0,0.35)
                        if (p.location != null)
                          Row(children: [
                            Icon(Icons.location_on,
                                size: 12,
                                color: Colors.black.withOpacity(0.45)),
                            const SizedBox(width: 2),
                            Text(p.location!,
                                style: GoogleFonts.figtree(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.35))),
                          ]),
                        const SizedBox(height: 6),

                        // Figma: member since badge — grey pill, 10px bold
                        if (p.memberSince != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x3D595959),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              'Member since ${DateFormat('MMMM yyyy').format(p.memberSince!)}',
                              style: GoogleFonts.figtree(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Figma: bio — 14px Medium
              if (p.bio != null && p.bio!.isNotEmpty)
                Text(p.bio!,
                    style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.5)),

              const SizedBox(height: 20),

              // Figma: stats row — Trips | Reviews | Wishlist | Ratings
              // Each: 20px bold number + 12px grey label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCell(value: p.tripsCount.toString(), label: 'Trips'),
                  _StatCell(value: p.reviewsCount.toString(), label: 'Reviews'),
                  _StatCell(value: p.wishlistCount.toString(), label: 'Wishlist'),
                  _StatCell(
                    value: p.avgRating > 0
                        ? p.avgRating.toStringAsFixed(1)
                        : '—',
                    label: 'Ratings',
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
  }

  Widget _buildNotSignedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Sign in to view your profile',
              style: GoogleFonts.figtree(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen())),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: const StadiumBorder()),
            child: Text('Sign In',
                style:
                    GoogleFonts.figtree(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            _SettingsRow(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () { Navigator.pop(context); _editProfile(); },
            ),
            _SettingsRow(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                // TODO: Open notification preferences screen
                // For now, acknowledge tap with feedback
              },
            ),
            _SettingsRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () async {
                Navigator.pop(context);
                await launchUrl(Uri.parse('https://hoppity.in/privacy'),
                    mode: LaunchMode.externalApplication);
              },
            ),
            const Divider(height: 24),
            _SettingsRow(
              icon: Icons.logout,
              label: 'Sign Out',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await ProfileService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    if (_profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(
        profile: _profile!,
        onSaved: (fullName, username, bio, location, profilePicUrl) {
          Navigator.pop(context);
          // Update UI immediately with new values
          if (mounted) {
            setState(() {
              _profile = UserProfile(
                userId: _profile!.userId,
                fullName: fullName.isEmpty ? _profile!.fullName : fullName,
                username: username.isEmpty ? _profile!.username : username,
                email: _profile!.email,
                bio: bio.isEmpty ? _profile!.bio : bio,
                location: location.isEmpty ? _profile!.location : location,
                profilePic: profilePicUrl ?? _profile!.profilePic,
                memberSince: _profile!.memberSince,
                tripsCount: _profile!.tripsCount,
                reviewsCount: _profile!.reviewsCount,
                wishlistCount: _profile!.wishlistCount,
                avgRating: _profile!.avgRating,
                followersCount: _profile!.followersCount,
                followingCount: _profile!.followingCount,
                postsCount: _profile!.postsCount,
                isCreator: _profile!.isCreator,
                isGuide: _profile!.isGuide,
              );
            });
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// STAT CELL — Figma: 20px ExtraBold number, 12px grey label, centered
// ─────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.figtree(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.figtree(
                  fontSize: 12, color: const Color(0xB2595959))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// STICKY TAB BAR DELEGATE
// ─────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onTap;
  final Color activeColor;

  const _TabBarDelegate({
    required this.tabs,
    required this.selected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.black.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(tabs[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      selected != old.selected || tabs != old.tabs;
}

// ─────────────────────────────────────────────────────────────────────
// OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final UserProfile profile;
  const _OverviewTab({required this.profile});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _content = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;



  Future<void> _openWhatsApp(BuildContext ctx, String message) async {
    final uri = Uri.parse('https://wa.me/919752377323?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp',
            style: GoogleFonts.figtree())),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await ProfileService.fetchMyContent();
    if (mounted) setState(() { _content = content; _loading = false; });
  }

  Future<void> _logout(BuildContext context) async {
    await ProfileService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ── My content section ─────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text('My content',
              style: GoogleFonts.figtree(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),

        _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ))
            : _content.isEmpty
                ? _buildEmptyContent()
                : _buildContentGrid(),

        const SizedBox(height: 28),

        // ── Creator Features section ───────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Creator Features',
              style: GoogleFonts.figtree(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),

        _FeatureCard(
          icon: Icons.explore_outlined,
          title: 'List a Guided Tour',
          subtitle: 'Offer your expertise as a certified guide.',
          color: AppTheme.primary,
          onTap: () => _openWhatsApp(context,
            'Hi Hoppity! I\'d like to list a guided tour on the app. I am a certified guide specialising in:'),
        ),
        _FeatureCard(
          icon: Icons.star_outline,
          title: 'Recommend & Earn',
          subtitle: 'Earn by suggesting tours to friends.',
          color: AppTheme.primary,
          onTap: () => _openWhatsApp(context,
            'Hi Hoppity! I\'d like to learn more about the Recommend & Earn programme.'),
        ),
        _FeatureCard(
          icon: Icons.inventory_2_outlined,
          title: 'Add a Package Tour',
          subtitle: 'Bundle experiences for travellers.',
          color: AppTheme.primary,
          onTap: () => _openWhatsApp(context,
            'Hi Hoppity! I\'d like to add a package tour. Here are the details:'),
        ),
        _FeatureCard(
          icon: Icons.edit_note_outlined,
          title: 'Curate a Niche Tour',
          subtitle: 'Design unique, themed tours.',
          color: AppTheme.primary,
          bottomMargin: 0,
          onTap: () => _openWhatsApp(context,
            'Hi Hoppity! I\'d like to curate a niche tour concept. Here\'s my idea:'),
        ),
        _LogoutFeatureButton(
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, color: Colors.grey, size: 40),
          const SizedBox(height: 8),
          Text('No posts yet',
              style: GoogleFonts.figtree(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContentGrid() {
    // Figma: 3 columns, each 100x130px rounded-10px tiles
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 100 / 130,
      ),
      itemCount: _content.length,
      itemBuilder: (_, i) {
        final item = _content[i];
        final imageUrl = item['image_url'] as String?;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.grey[200]),
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.white54, size: 32),
                ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final double bottomMargin;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.bottomMargin = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomMargin),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.26)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 36),
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.figtree(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.35))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _LogoutFeatureButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutFeatureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        height: 62,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: GoogleFonts.figtree(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SAVED TAB — Wishlist of saved tours
// ─────────────────────────────────────────────────────────────────────
class _SavedTab extends StatefulWidget {
  const _SavedTab();

  @override
  State<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<_SavedTab>
    with AutomaticKeepAliveClientMixin {
  List<Tour> _tours = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tours = await ProfileService.fetchSavedTours();
    if (mounted) setState(() { _tours = tours; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_tours.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No saved tours yet',
              style: GoogleFonts.figtree(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Bookmark tours from the feed',
              style: GoogleFonts.figtree(color: Colors.grey[400], fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tours.length,
      itemBuilder: (_, i) => _TourListTile(
        tour: _tours[i],
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => TourDetailScreen(tour: _tours[i]))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TRIPS TAB — Past bookings
// ─────────────────────────────────────────────────────────────────────
class _TripsTab extends StatelessWidget {
  const _TripsTab();

  @override
  Widget build(BuildContext context) {
    // Delegate to MyBookingsScreen for the full booking management flow
    // (Upcoming / Past / Cancelled tabs, cancel flow, review flow)
    return MyBookingsScreen(embedded: true);
  }
}

// ─────────────────────────────────────────────────────────────────────
// REVIEWS TAB — User's written reviews
// ─────────────────────────────────────────────────────────────────────
class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab>
    with AutomaticKeepAliveClientMixin {
  List<UserReview> _reviews = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ProfileService.fetchMyReviews();
    if (mounted) setState(() { _reviews = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_reviews.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No reviews yet',
              style: GoogleFonts.figtree(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Write a review after completing a tour',
              style: GoogleFonts.figtree(color: Colors.grey[400], fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (_, i) {
        final r = _reviews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (r.tourImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                        imageUrl: r.tourImage!,
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 44, height: 44, color: Colors.grey[200],
                          child: const Icon(Icons.broken_image_outlined,
                              size: 18, color: Colors.grey))),

                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.tourTitle,
                          style: GoogleFonts.figtree(
                              fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Row(
                        children: List.generate(5, (j) => Icon(
                          j < r.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber, size: 14,
                        )),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM yy').format(r.createdAt),
                  style: GoogleFonts.figtree(
                      fontSize: 11, color: Colors.grey),
                ),
              ]),
              if (r.reviewText != null && r.reviewText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r.reviewText!,
                    style: GoogleFonts.figtree(
                        fontSize: 14, height: 1.4, color: Colors.black87)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SHARED: Tour list tile (used in Saved tab)
// ─────────────────────────────────────────────────────────────────────
class _TourListTile extends StatelessWidget {
  final Tour tour;
  final VoidCallback onTap;
  const _TourListTile({required this.tour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: tour.primaryImage != null
                  ? CachedNetworkImage(
                      imageUrl: tour.primaryImage!,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 72, height: 72, color: Colors.grey[200],
                        child: const Icon(Icons.broken_image_outlined,
                            size: 28, color: Colors.grey)))
                  : Container(width: 72, height: 72, color: Colors.grey[200]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tour.title,
                      style: GoogleFonts.figtree(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(tour.location,
                        style: GoogleFonts.figtree(
                            fontSize: 12, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(tour.categoryColor).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tour.category,
                          style: GoogleFonts.figtree(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(tour.categoryColor))),
                    ),
                    const SizedBox(width: 6),
                    Text(tour.durationDisplay,
                        style: GoogleFonts.figtree(
                            fontSize: 11, color: Colors.grey)),
                  ]),
                ],
              ),
            ),
            Text(
                tour.pricePerPerson <= 0
                    ? 'On Request'
                    : tour.pricePerPerson >= 1000
                        ? '₹${(tour.pricePerPerson / 1000).toStringAsFixed(tour.pricePerPerson % 1000 == 0 ? 0 : 1)}K'
                        : '₹${tour.pricePerPerson.toStringAsFixed(0)}',
                style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SETTINGS ROW
// ─────────────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style:
              GoogleFonts.figtree(fontSize: 16, color: c, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// EDIT PROFILE SHEET
// ─────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  final void Function(String fullName, String username, String bio, String location, String? profilePicUrl) onSaved;
  const _EditProfileSheet({required this.profile, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  bool _saving = false;
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.fullName ?? '');
    _usernameCtrl = TextEditingController(text: widget.profile.username ?? '');
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
    _locationCtrl = TextEditingController(text: widget.profile.location ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? newPicUrl;
      if (_pickedBytes != null) {
        newPicUrl = await ProfileService.uploadAvatar(PlatformFile(
          name: 'avatar.$_pickedExt',
          mimeType: 'image/$_pickedExt',
          bytes: _pickedBytes!,
        ));
      }
      await ProfileService.updateProfile(
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        profilePicUrl: newPicUrl,
      );
      if (mounted) {
        setState(() => _saving = false);
        widget.onSaved(
          _nameCtrl.text.trim(),
          _usernameCtrl.text.trim(),
          _bioCtrl.text.trim(),
          _locationCtrl.text.trim(),
          newPicUrl,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Edit Profile',
              style: GoogleFonts.figtree(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _pickedBytes != null
                        ? MemoryImage(_pickedBytes!)
                        : (widget.profile.profilePic != null
                            ? CachedNetworkImageProvider(widget.profile.profilePic!)
                            : null) as ImageProvider?,
                    child: (_pickedBytes == null && widget.profile.profilePic == null)
                        ? Text(
                            widget.profile.displayName.isNotEmpty
                                ? widget.profile.displayName[0].toUpperCase()
                                : 'T',
                            style: GoogleFonts.figtree(
                                fontSize: 32, fontWeight: FontWeight.w700,
                                color: Colors.grey[600]),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _EditField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline),
          const SizedBox(height: 12),
          _EditField(controller: _usernameCtrl, label: 'Username', icon: Icons.alternate_email),
          const SizedBox(height: 12),
          _EditField(controller: _locationCtrl, label: 'Location', icon: Icons.location_on_outlined),
          const SizedBox(height: 12),
          _EditField(controller: _bioCtrl, label: 'Bio', icon: Icons.edit_outlined, maxLines: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: const StadiumBorder()),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Save Changes',
                      style: GoogleFonts.figtree(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.figtree(color: Colors.grey),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      );
}
