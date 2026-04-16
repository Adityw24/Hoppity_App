import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tour.dart';
import '../services/search_service.dart';
import '../theme/app_theme.dart';
import '../widgets/itinerary_card.dart';
import 'tour_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
// SearchScreen
// Dedicated search experience:
//   • Auto-focused bar — opens straight to keyboard
//   • Phase 1 (empty bar): Recent searches + Trending
//   • Phase 2 (typing):    Live suggestions via DB RPC
//   • Phase 3 (submitted): Full ranked results with filter chips
// ─────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // ── Controllers ─────────────────────────────────────────────
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  Timer? _debounce;

  // ── State ────────────────────────────────────────────────────
  String _query = '';
  bool   _searching = false;   // RPC in flight
  bool   _hasResults = false;  // true after first submit

  // Phase 1
  List<String> _recent   = [];
  List<String> _trending = [];

  // Phase 2
  List<SearchSuggestion> _suggestions = [];

  // Phase 3 — results + active filter chips
  List<SearchResult> _results    = [];
  String?  _filterCategory;
  String?  _filterState;
  String?  _filterDifficulty;

  // Available distinct filter values from results
  List<String> _availableCategories  = [];
  List<String> _availableStates      = [];
  List<String> _availableDifficulties = [];

  @override
  void initState() {
    super.initState();
    _loadPhase1();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Phase 1: load recent + trending ──────────────────────────
  Future<void> _loadPhase1() async {
    final r = await SearchService.getRecent();
    final t = await SearchService.trending(limit: 10);
    if (mounted) setState(() { _recent = r; _trending = t; });
  }

  // ── Phase 2: debounced suggestion fetch ──────────────────────
  void _onQueryChanged(String value) {
    setState(() { _query = value; _hasResults = false; });
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final s = await SearchService.suggestions(value.trim());
      if (mounted) setState(() => _suggestions = s);
    });
  }

  // ── Phase 3: execute full search ─────────────────────────────
  Future<void> _submitSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    _focus.unfocus();
    setState(() {
      _query = query;
      _ctrl.text = query;
      _searching = true;
      _suggestions = [];
      _filterCategory = null;
      _filterState = null;
      _filterDifficulty = null;
    });
    await SearchService.recordSearch(query);
    final results = await SearchService.search(query: query, limit: 40);
    if (!mounted) return;
    // Extract distinct filter values from result set
    final cats  = results.map((r) => r.category).toSet().toList()..sort();
    final states = results.map((r) => r.state).where((s) => s != null).cast<String>().toSet().toList()..sort();
    final diffs  = results.map((r) => r.difficulty).toSet().toList();
    setState(() {
      _results = results;
      _hasResults = true;
      _searching = false;
      _availableCategories  = cats;
      _availableStates      = states;
      _availableDifficulties = diffs;
    });
    await _loadPhase1(); // refresh recent
  }

  // ── Apply filter chips to current results ────────────────────
  List<SearchResult> get _filteredResults {
    return _results.where((r) {
      if (_filterCategory  != null && r.category != _filterCategory)  return false;
      if (_filterState     != null && r.state    != _filterState)     return false;
      if (_filterDifficulty != null && r.difficulty != _filterDifficulty) return false;
      return true;
    }).toList();
  }

  bool get _anyFilterActive =>
      _filterCategory != null || _filterState != null || _filterDifficulty != null;

  void _clearFilters() => setState(() {
    _filterCategory = null; _filterState = null; _filterDifficulty = null;
  });

  // ── Open a tour ───────────────────────────────────────────────
  void _open(Tour tour) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: _onQueryChanged,
                onSubmitted: _submitSearch,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.figtree(fontSize: 15, color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search tours, places, experiences…',
                  hintStyle: GoogleFonts.figtree(
                    fontSize: 14, color: Colors.black.withOpacity(0.38)),
                  prefixIcon: Icon(Icons.search,
                    color: Colors.black.withOpacity(0.38), size: 20),
                  suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.black38,
                        onPressed: () {
                          _ctrl.clear();
                          setState(() {
                            _query = '';
                            _suggestions = [];
                            _hasResults = false;
                            _results = [];
                          });
                          _focus.requestFocus();
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text('Cancel',
              style: GoogleFonts.figtree(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ── Body switcher ─────────────────────────────────────────────
  Widget _buildBody() {
    if (_searching) return _buildLoading();
    if (_hasResults) return _buildResults();
    if (_query.length >= 2 && _suggestions.isNotEmpty) return _buildSuggestions();
    return _buildPhase1();
  }

  // ── Phase 1: empty state ──────────────────────────────────────
  Widget _buildPhase1() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        // Recent searches
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            Text('Recent', style: GoogleFonts.figtree(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await SearchService.clearRecent();
                setState(() => _recent = []);
              },
              child: Text('Clear all', style: GoogleFonts.figtree(
                fontSize: 12, color: Colors.red.shade400,
                fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          ..._recent.map((q) => _RecentChip(
            query: q,
            onTap: () => _submitSearch(q),
            onDismiss: () async {
              await SearchService.removeRecent(q);
              setState(() => _recent.remove(q));
            },
          )),
        ],

        // Trending searches
        if (_trending.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.trending_up, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text('Trending searches', style: GoogleFonts.figtree(
              fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _trending.map((t) => GestureDetector(
              onTap: () => _submitSearch(t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.20)),
                ),
                child: Text(t, style: GoogleFonts.figtree(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark)),
              ),
            )).toList(),
          ),
        ],

        // Browse by category
        const SizedBox(height: 28),
        Text('Browse by category', style: GoogleFonts.figtree(
          fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: _categories.map((c) => _CategoryTile(
            emoji: c.$1, label: c.$2, color: c.$3,
            onTap: () => _submitSearch(c.$2),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Phase 2: live suggestions ─────────────────────────────────
  Widget _buildSuggestions() {
    return ListView(
      padding: EdgeInsets.zero,
      children: _suggestions.map((s) {
        final isPlace = s.type == 'place' || s.type == 'state';
        return ListTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isPlace
                ? Colors.blue.withOpacity(0.10)
                : AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPlace ? Icons.location_on : Icons.explore,
              size: 18,
              color: isPlace ? Colors.blue : AppTheme.primary,
            ),
          ),
          title: _HighlightText(text: s.label, query: _query),
          subtitle: s.category != null
            ? Text(s.category!, style: GoogleFonts.figtree(
                fontSize: 11, color: Colors.black38))
            : Text(s.type == 'state' ? 'State' : 'Location',
                style: GoogleFonts.figtree(
                  fontSize: 11, color: Colors.black38)),
          trailing: const Icon(Icons.north_west, size: 14, color: Colors.black26),
          onTap: () => _submitSearch(s.label),
          onLongPress: () {
            _ctrl.text = s.label;
            _ctrl.selection = TextSelection.fromPosition(
              TextPosition(offset: s.label.length));
            setState(() => _query = s.label);
          },
        );
      }).toList(),
    );
  }

  // ── Phase 3: results ─────────────────────────────────────────
  Widget _buildResults() {
    final shown = _filteredResults;
    return Column(
      children: [
        // Filter chips row
        if (_results.isNotEmpty) _buildFilterRow(),

        // Results count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Text('${shown.length} result${shown.length == 1 ? '' : 's'}',
                style: GoogleFonts.figtree(
                  fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('for "$_query"',
                style: GoogleFonts.figtree(
                  fontSize: 13, color: Colors.black45)),
              const Spacer(),
              if (_anyFilterActive)
                GestureDetector(
                  onTap: _clearFilters,
                  child: Text('Clear filters',
                    style: GoogleFonts.figtree(
                      fontSize: 12, color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: shown.isEmpty
            ? _buildNoResults()
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: shown.length,
                itemBuilder: (_, i) => ItineraryCard(
                  tour: shown[i],
                  style: ItineraryCardStyle.list,
                  onTap: () => _open(shown[i]),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Category chips
          ..._availableCategories.map((c) => _FilterChip(
            label: c,
            active: _filterCategory == c,
            onTap: () => setState(() =>
              _filterCategory = _filterCategory == c ? null : c),
          )),
          // Difficulty chips
          ..._availableDifficulties.map((d) => _FilterChip(
            label: d,
            active: _filterDifficulty == d,
            color: d == 'Easy'
              ? Colors.green : d == 'Challenging'
              ? Colors.red : Colors.orange,
            onTap: () => setState(() =>
              _filterDifficulty = _filterDifficulty == d ? null : d),
          )),
          // State chips
          ..._availableStates.take(5).map((s) => _FilterChip(
            label: s,
            active: _filterState == s,
            color: Colors.blue,
            onTap: () => setState(() =>
              _filterState = _filterState == s ? null : s),
          )),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No tours found for "$_query"',
            style: GoogleFonts.figtree(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Try different keywords or browse by category',
            style: GoogleFonts.figtree(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center),
          if (_anyFilterActive) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: AppTheme.primary)),
              child: Text('Remove filters',
                style: GoogleFonts.figtree(
                  color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2));
  }

  // Category data: (emoji, label, Color)
  static const _categories = [
    ('🏛️', 'Heritage',   Color(0xFF5D4037)),
    ('🥾', 'Trekking',   Color(0xFF2E7D32)),
    ('🏄', 'Adventure',  Color(0xFFE65100)),
    ('🐘', 'Wildlife',   Color(0xFF4E342E)),
    ('🍛', 'Culinary',   Color(0xFFAD1457)),
    ('🕉️', 'Spiritual',  Color(0xFF6A1B9A)),
    ('🎭', 'Cultural',   Color(0xFF1565C0)),
    ('🔍', 'All tours',  AppTheme.primary),
  ];
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _RecentChip extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _RecentChip({required this.query, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.history, size: 16, color: Colors.black38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(query,
                style: GoogleFonts.figtree(
                  fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: Colors.black26),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.emoji, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 5),
          Text(label,
            style: GoogleFonts.figtree(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active,
    required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(label,
          style: GoogleFonts.figtree(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.black87)),
      ),
    );
  }
}

// Highlights matched query text in bold
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final idx = lower.indexOf(lowerQ);
    if (idx < 0) {
      return Text(text, style: GoogleFonts.figtree(fontSize: 14));
    }
    return Text.rich(TextSpan(
      style: GoogleFonts.figtree(fontSize: 14, color: Colors.black),
      children: [
        TextSpan(text: text.substring(0, idx)),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: const TextStyle(
            fontWeight: FontWeight.w800, color: AppTheme.primary)),
        TextSpan(text: text.substring(idx + query.length)),
      ],
    ));
  }
}
