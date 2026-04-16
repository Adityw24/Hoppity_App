import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tour.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/itinerary_card.dart';
import 'tour_detail_screen.dart';
import 'search_screen.dart';

// Sort options
enum SortOption { relevance, ratingHigh, priceLow, priceHigh, durationShort }

extension SortLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevance:     return 'Most Relevant';
      case SortOption.ratingHigh:    return 'Highest Rated';
      case SortOption.priceLow:      return 'Price: Low → High';
      case SortOption.priceHigh:     return 'Price: High → Low';
      case SortOption.durationShort: return 'Shortest First';
    }
  }
}

class ItineraryListingScreen extends StatefulWidget {
  /// Optional — if provided, pre-filters by this category
  final String? initialCategory;

  const ItineraryListingScreen({super.key, this.initialCategory});

  @override
  State<ItineraryListingScreen> createState() =>
      _ItineraryListingScreenState();
}

class _ItineraryListingScreenState
    extends State<ItineraryListingScreen> {
  // Data
  List<Tour> _allTours = [];
  List<Tour> _filtered = [];
  bool _loading = true;

  // Search & filter state
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  Set<String> _selectedDifficulties = {};
  double _maxPrice = 50000;
  SortOption _sort = SortOption.relevance;

  // View toggle
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tours = await TourService.fetchTours(limit: 40);
      debugPrint('[ItineraryScreen] loaded ${tours.length} tours');
      if (mounted) {
        setState(() {
          _allTours = tours;
          _loading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('[ItineraryScreen] _load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var result = List<Tour>.from(_allTours);
    final q = _searchCtrl.text.trim().toLowerCase();

    // Search
    if (q.isNotEmpty) {
      result = result.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.location.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            t.category.toLowerCase().contains(q) ||
            (t.state?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Category
    if (_selectedCategory != 'All') {
      result = result
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Difficulty
    if (_selectedDifficulties.isNotEmpty) {
      result = result
          .where((t) => _selectedDifficulties.contains(t.difficulty))
          .toList();
    }

    // Price
    result = result
        .where((t) => t.pricePerPerson <= _maxPrice || t.pricePerPerson == 0)
        .toList();

    // Sort
    switch (_sort) {
      case SortOption.ratingHigh:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.priceLow:
        result.sort((a, b) => a.pricePerPerson.compareTo(b.pricePerPerson));
        break;
      case SortOption.priceHigh:
        result.sort((a, b) => b.pricePerPerson.compareTo(a.pricePerPerson));
        break;
      case SortOption.durationShort:
        // Sort by price_per_person as duration proxy (no parsed duration field)
        result.sort((a, b) => a.pricePerPerson.compareTo(b.pricePerPerson));
        break;
      case SortOption.relevance:
        result.sort((a, b) =>
            (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount));
        break;
    }

    setState(() => _filtered = result);
  }

  void _onSearchChanged(String _) => _applyFilters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : _isGridView
                        ? _buildGrid()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Sticky header: title + search + category strip ────────────────
  Widget _buildHeader() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top nav bar — matches Figma: white, border-bottom
          Container(
            height: kIsWeb ? 64 : 91,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.10))),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: kIsWeb ? 12 : MediaQuery.of(context).padding.top + 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Explore Guided Tours',
                    style: GoogleFonts.figtree(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Grid / List toggle
                GestureDetector(
                  onTap: () => setState(() => _isGridView = !_isGridView),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters
                          ? AppTheme.primary.withOpacity(0.10)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: _hasActiveFilters
                          ? Border.all(color: AppTheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 20,
                          color: _hasActiveFilters
                              ? AppTheme.primary
                              : Colors.black87,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            top: 0, right: 0,
                            child: Container(
                              width: 7, height: 7,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar — Figma: rounded full-width, grey bg
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: GestureDetector(
                onTap: () async {
                  // Open dedicated SearchScreen as a slide-up modal
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const SearchScreen(),
                    ),
                  );
                },
                child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                readOnly: false,
                style: GoogleFonts.figtree(fontSize: 15, color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search tours, places, experiences...',
                  hintStyle: GoogleFonts.figtree(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.40),
                  ),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.black.withOpacity(0.40), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.black.withOpacity(0.40),
                          onPressed: () {
                            _searchCtrl.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              ),
            ),
          ),

          // Category strip — horizontal scroll, Figma style
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: TourService.categories.length,
              itemBuilder: (_, i) {
                final cat = TourService.categories[i];
                final selected = _selectedCategory == cat;
                final catColor = cat == 'All'
                    ? AppTheme.primary
                    : Color(Tour.categoryColors[cat] ?? 0xFF7C3AED);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? catColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: selected
                          ? null
                          : Border.all(
                              color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Results count + sort row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} tour${_filtered.length == 1 ? '' : 's'}',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (_selectedCategory != 'All') ...[
                  Text(
                    ' · $_selectedCategory',
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ],
                const Spacer(),
                // Sort chip
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 14,
                            color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          _sort.label.split(':').first,
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
        ],
      );
  }

  // ── Grid view — Figma: 2-column with spacing ──────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Ratio tuned so image (130) + content (~85) fits without overflow
        childAspectRatio: 0.72,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => ItineraryCard(
        tour: _filtered[i],
        style: ItineraryCardStyle.grid,
        onTap: () => _openDetail(_filtered[i]),
      ),
    );
  }

  // ── List view — full-width cards with more detail ─────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => ItineraryCard(
        tour: _filtered[i],
        style: ItineraryCardStyle.list,
        onTap: () => _openDetail(_filtered[i]),
      ),
    );
  }

  // ── Skeleton loading ──────────────────────────────────────────────
  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 13,
                      width: double.infinity,
                      color: Colors.grey[200]),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 80, color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Container(height: 11, width: 120, color: Colors.grey[200]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No tours match "${_searchCtrl.text}"'
                  : 'No tours found',
              style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or remove some filters',
              style: GoogleFonts.figtree(
                  fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppTheme.primary)),
              child: Text('Clear filters',
                  style: GoogleFonts.figtree(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Tour tour) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TourDetailScreen(tour: tour)));
  }

  bool get _hasActiveFilters =>
      _selectedDifficulties.isNotEmpty || _maxPrice < 50000;

  void _clearAllFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedCategory = 'All';
      _selectedDifficulties = {};
      _maxPrice = 50000;
      _sort = SortOption.relevance;
    });
    _applyFilters();
  }

  // ── Filter bottom sheet ───────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        selectedDifficulties: _selectedDifficulties,
        maxPrice: _maxPrice,
        onApply: (diffs, maxPrice) {
          setState(() {
            _selectedDifficulties = diffs;
            _maxPrice = maxPrice;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedDifficulties = {};
            _maxPrice = 50000;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Sort by',
                style: GoogleFonts.figtree(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...SortOption.values.map((opt) {
              final selected = _sort == opt;
              return GestureDetector(
                onTap: () {
                  setState(() => _sort = opt);
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      vertical: 13, horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(
                            color: AppTheme.primary.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(opt.label,
                          style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.black87)),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check,
                            color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Filter Sheet
// ─────────────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final Set<String> selectedDifficulties;
  final double maxPrice;
  final void Function(Set<String> diffs, double maxPrice) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.selectedDifficulties,
    required this.maxPrice,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _diffs;
  late double _maxPrice;

  @override
  void initState() {
    super.initState();
    _diffs = Set.from(widget.selectedDifficulties);
    _maxPrice = widget.maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Filter',
                  style: GoogleFonts.figtree(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: widget.onClear,
                child: Text('Clear all',
                    style: GoogleFonts.figtree(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty
          Text('Difficulty',
              style: GoogleFonts.figtree(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: ['Easy', 'Moderate', 'Challenging'].map((d) {
              final sel = _diffs.contains(d);
              // Difficulty chip colours via Tour model's difficultyColor
              Color c;
              switch (d) {
                case 'Easy':       c = const Color(0xFF2E7D32); break;
                case 'Challenging': c = const Color(0xFFB71C1C); break;
                default:           c = const Color(0xFFE65100); // Moderate
              }
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                      () => sel ? _diffs.remove(d) : _diffs.add(d)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? c.withOpacity(0.12) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: sel
                          ? Border.all(color: c, width: 1.5)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: sel ? c : Colors.grey[700])),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Max price
          Row(
            children: [
              Text('Max price per person',
                  style: GoogleFonts.figtree(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                _maxPrice >= 50000
                    ? 'Any'
                    : '₹${(_maxPrice / 1000).toStringAsFixed(0)}K',
                style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
              ),
            ],
          ),
          Slider(
            value: _maxPrice,
            min: 500,
            max: 50000,
            divisions: 99,
            activeColor: AppTheme.primary,
            inactiveColor: Colors.grey[200],
            onChanged: (v) => setState(() => _maxPrice = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹500',
                  style: GoogleFonts.figtree(
                      fontSize: 11, color: Colors.grey)),
              Text('₹50K+',
                  style: GoogleFonts.figtree(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),

          // Apply
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_diffs, _maxPrice),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0),
              child: Text('Apply filters',
                  style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
