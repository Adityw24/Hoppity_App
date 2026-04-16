import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tour.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/for_you_card.dart';
import 'tour_detail_screen.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
    with AutomaticKeepAliveClientMixin {
  List<RecommendedTour> _tours = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Ask for location on first load
    await RecommendationService.requestLocationPermission();
    await _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_refreshing) return;
    setState(() {
      if (_tours.isEmpty) _loading = true;
      _refreshing = true;
    });

    try {
      final tours = await RecommendationService.fetchForYou(
        forceRefresh: force,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _tours = tours;
          _loading = false;
          _refreshing = false;
        });
        // Mark as seen
        RecommendationService.markSeen(tours.map((t) => t.id).toList());
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _refreshing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildSkeleton()
          : _tours.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => _load(force: true),
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _tours.length + 1, // +1 for personalisation tip
                    itemBuilder: (_, i) {
                      if (i == 2) return _buildPersonalisationTip();
                      final idx = i > 2 ? i - 1 : i;
                      if (idx >= _tours.length) return const SizedBox.shrink();
                      return ForYouCard(
                        tour: _tours[idx],
                        onViewDetails: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TourDetailScreen(tour: _tours[idx])),
                        ),
                        onBookNow: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TourDetailScreen(tour: _tours[idx])),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text('For You',
          style: GoogleFonts.figtree(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black)),
      actions: [
        IconButton(
          icon: const Icon(Icons.send_outlined, color: Colors.black, size: 26),
          onPressed: () async {
            final uri = Uri.parse(
              'https://wa.me/919752377323?text=Hi%20Hoppity%21%20I%20have%20a%20question%20about%20a%20tour.');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.black, size: 26),
          onPressed: _showPreferencesPicker,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: LinearProgressIndicator(
          value: _refreshing ? null : 1.0,
          backgroundColor: Colors.transparent,
          color: _refreshing ? AppTheme.primary : Colors.transparent,
          minHeight: 2,
        ),
      ),
    );
  }

  // ── Loading skeleton ─────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 420,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 214,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: 220, height: 20),
                  const SizedBox(height: 8),
                  _SkeletonLine(width: 160, height: 14),
                  const SizedBox(height: 8),
                  _SkeletonLine(width: double.infinity, height: 14),
                  const SizedBox(height: 4),
                  _SkeletonLine(width: 260, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Personalisation tip card ──────────────────────────────────
  Widget _buildPersonalisationTip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.08),
            AppTheme.primaryLight.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personalised for you',
                    style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                Text(
                  'This feed learns from your bookings, saves, and how long you spend on each card.',
                  style: GoogleFonts.figtree(
                      fontSize: 12, color: Colors.black.withOpacity(0.55), height: 1.4),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showPreferencesPicker,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0)),
            child: Text('Tune',
                style: GoogleFonts.figtree(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No recommendations yet',
              style: GoogleFonts.figtree(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Book or save a tour to train your feed',
              style: GoogleFonts.figtree(fontSize: 13, color: Colors.grey[400])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _load(force: true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: const StadiumBorder()),
            child: Text('Refresh',
                style: GoogleFonts.figtree(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Preference picker bottom sheet ────────────────────────────
  void _showPreferencesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PreferencePicker(
        onSaved: () {
          Navigator.pop(context);
          _load(force: true);
        },
      ),
    );
  }
}

// ── Preference picker ────────────────────────────────────────────
class _PreferencePicker extends StatefulWidget {
  final VoidCallback onSaved;
  const _PreferencePicker({required this.onSaved});

  @override
  State<_PreferencePicker> createState() => _PreferencePickerState();
}

class _PreferencePickerState extends State<_PreferencePicker> {
  final _categories = ['Heritage', 'Trekking', 'Adventure', 'Wildlife', 'Culinary', 'Spiritual', 'Cultural'];
  final Set<String> _selected = {};
  double _budgetMin = 500;
  double _budgetMax = 20000;
  String _difficulty = 'Moderate';
  bool _saving = false;

  final _catIcons = {
    'Heritage': Icons.account_balance,
    'Trekking': Icons.terrain,
    'Adventure': Icons.kayaking,
    'Wildlife': Icons.pets,
    'Culinary': Icons.restaurant,
    'Spiritual': Icons.self_improvement,
    'Cultural': Icons.theater_comedy,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Tune your recommendations',
              style: GoogleFonts.figtree(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Select what you love — your feed will update instantly',
              style: GoogleFonts.figtree(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),

          Text('Favourite categories',
              style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((cat) {
              final sel = _selected.contains(cat);
              final color = Color(Tour.categoryColors[cat] ?? 0xFF7C3AED);
              return GestureDetector(
                onTap: () => setState(() => sel ? _selected.remove(cat) : _selected.add(cat)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.15) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? color : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcons[cat], size: 15, color: sel ? color : Colors.grey),
                      const SizedBox(width: 5),
                      Text(cat,
                          style: GoogleFonts.figtree(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? color : Colors.grey[700])),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('Budget per person: ₹${_budgetMin.toInt()} – ₹${_budgetMax.toInt()}',
              style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w700)),
          RangeSlider(
            values: RangeValues(_budgetMin, _budgetMax),
            min: 500, max: 50000, divisions: 99,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() { _budgetMin = v.start; _budgetMax = v.end; }),
          ),
          const SizedBox(height: 8),

          Text('Preferred difficulty',
              style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: ['Easy', 'Moderate', 'Challenging'].map((d) {
              final sel = _difficulty == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.grey[700])),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: const StadiumBorder()),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Update my feed',
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

  Future<void> _save() async {
    setState(() => _saving = true);
    await RecommendationService.saveExplicitPreferences(
      favoriteCategories: _selected.toList(),
      budgetMin: _budgetMin,
      budgetMax: _budgetMax,
      preferredDifficulty: _difficulty,
    );
    if (mounted) {
      setState(() => _saving = false);
      widget.onSaved();
    }
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
