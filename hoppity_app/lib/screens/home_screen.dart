import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tour.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tour_feed_card.dart';
import '../widgets/responsive_wrapper.dart';
import 'tour_detail_screen.dart';
import 'community_hub_screen.dart';
import 'profile_screen.dart';
import 'for_you_screen.dart';
import 'itinerary_listing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  List<Tour> _tours = [];
  bool _loading = true;
  int _navIndex = 0;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadTours();
    // Light status bar icons on dark feed background — works on both iOS and Android
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,           // Android
      statusBarBrightness: Brightness.light,        // iOS: dark icons on white
      statusBarIconBrightness: Brightness.dark,     // Android: dark icons on white
    ));
  }

  Future<void> _loadTours({String? category}) async {
    setState(() => _loading = true);
    try {
      final tours = await TourService.fetchTours(
        category: category == 'All' ? null : category,
        limit: 40,
      );
      debugPrint('[HomeScreen] loaded ${tours.length} tours');
      if (mounted) setState(() { _tours = tours; _loading = false; });
    } catch (e) {
      debugPrint('[HomeScreen] _loadTours error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildFeed(),
          const ForYouScreen(),
          const ItineraryListingScreen(),
          const CommunityHubScreen(),
          const ProfileScreen(),
        ],
      ),
      // Hide bottom nav on web desktop — sidebar handles navigation
      bottomNavigationBar: kIsWeb ? null : _buildBottomNav(),
    );

    return ResponsiveWrapper(
      navIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      showNav: kIsWeb,
      child: scaffold,
    );
  }

  Widget _buildFeed() {
    return Stack(
      children: [
        // ── Main TikTok-style vertical page feed ───────────────
        _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _tours.isEmpty
                ? _buildEmpty()
                : WebAwarePageView(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _tours.length,
                    onPageChanged: (index) => setState(() {}),
                    itemBuilder: (_, i) => TourFeedCard(
                      tour: _tours[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TourDetailScreen(tour: _tours[i])),
                      ),
                      onBook: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TourDetailScreen(tour: _tours[i])),
                      ),
                    ),
                  ),

        // ── Top navbar ─────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: ColoredBox(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Hoppity',
                        style: GoogleFonts.figtree(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    const Spacer(),
                    IconButton(
                      onPressed: _shareTour,
                      icon: const Icon(Icons.send_outlined,
                          color: Colors.black, size: 26),
                    ),
                    IconButton(
                      onPressed: _showCategoryFilter,
                      icon: const Icon(Icons.tune, color: Colors.black, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),


      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, color: Colors.white38, size: 64),
          const SizedBox(height: 12),
          Text('No tours found',
              style: GoogleFonts.figtree(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _loadTours(),
            child: Text('Refresh',
                style: GoogleFonts.figtree(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (Icons.home_rounded,     'Home'),
      (Icons.auto_awesome,     'For You'),
      (Icons.explore_outlined, 'Tours'),
      (Icons.people_outline,   'Community'),
      (Icons.person_outline,   'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _navIndex == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _navIndex = i),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$1,
                          color: selected ? AppTheme.primary : Colors.white38,
                          size: 24,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$2,
                          style: GoogleFonts.figtree(
                            fontSize: 10,
                            color: selected
                                ? AppTheme.primary
                                : Colors.white38,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _shareTour() async {
    if (_tours.isEmpty) return;
    final idx = _pageController.hasClients
        ? (_pageController.page?.round() ?? 0)
        : 0;
    final tour = _tours[idx.clamp(0, _tours.length - 1)];
    final text = 'Check out "${tour.title}" on Hoppity!\nhoppity.in';
    // wa.me without a phone number opens WhatsApp's forward/share UI
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp',
                style: GoogleFonts.figtree()),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    }
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Category',
                style: GoogleFonts.figtree(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TourService.categories.map((cat) {
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _loadTours(category: cat);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat,
                        style: GoogleFonts.figtree(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
