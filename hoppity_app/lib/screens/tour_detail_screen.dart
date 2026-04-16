import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tour.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'booking_review_screen.dart';

class TourDetailScreen extends StatefulWidget {
  final Tour tour;
  const TourDetailScreen({super.key, required this.tour});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  int _selectedImage = 0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[TourDetail] tour: id=${widget.tour.id}, title=${widget.tour.title}, '
        'image=${widget.tour.primaryImage}, price=${widget.tour.pricePerPerson}');
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await ProfileService.isTourSaved(widget.tour.id);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    final newState = !_isSaved;
    setState(() => _isSaved = newState);
    if (newState) {
      await ProfileService.saveTour(widget.tour.id);
    } else {
      await ProfileService.unsaveTour(widget.tour.id);
    }
  }

  // _numPersons and _booking moved to BookingReviewScreen
  // This screen now previews the tour and routes to booking flow

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final allImages = [
      if (tour.primaryImage != null) tour.primaryImage!,
      ...tour.images.where((img) => img != tour.primaryImage),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero image (Figma: 419px tall, 30px radius) ──────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: allImages.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: allImages[_selectedImage],
                            height: 380,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(height: 380, color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => Container(
                              height: 380,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image_outlined,
                                  size: 48, color: Colors.grey),
                            ),
                          )
                        : Container(
                            height: 380,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No image available',
                                    style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          ),
                  ),
                  // Back button
                  Positioned(
                    top: 14,
                    left: 14,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  // Category chip — top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.2), Color(tour.categoryColor)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        tour.category,
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bookmark/save button — below category chip
                  Positioned(
                    top: 62,
                    right: 14,
                    child: GestureDetector(
                      onTap: _toggleSave,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved ? AppTheme.primary : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title (Figma: 26px bold) ─────────────────
                  Text(
                    tour.title,
                    style: GoogleFonts.figtree(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  // ── Quick-stats chips ────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(icon: Icons.access_time, label: tour.durationDisplay),
                      _StatChip(icon: Icons.location_on, label: tour.location),
                      _StatChip(
                        icon: Icons.signal_cellular_alt,
                        label: tour.difficulty,
                        color: Color(tour.difficultyColor),
                      ),
                      _StatChip(icon: Icons.people, label: 'Max ${tour.maxGroupSize}'),
                      if (tour.rating > 0)
                        _StatChip(icon: Icons.star, label: '${tour.rating} (${tour.reviewCount})', color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Tour Details section (Figma: SemiBold 18px) ─
                  Text('Tour Details',
                      style: GoogleFonts.figtree(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  // Description (Figma: italic medium 15px)
                  if (tour.description != null)
                    Text(
                      tour.description!,
                      style: GoogleFonts.figtree(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Photo grid + See all (Figma: 75px tiles) ──
                  if (allImages.length > 1) ...[
                    Row(
                      children: [
                        Text('Photos',
                            style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: allImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setState(() => _selectedImage = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _selectedImage == i ? AppTheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: CachedNetworkImage(
                                imageUrl: allImages[i],
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,                                errorWidget: (_, __, ___) => Container(
                                  width: 75, height: 75, color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image_outlined,
                                      size: 24, color: Colors.grey),
                                ),                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Highlights ───────────────────────────────
                  if (tour.highlights.isNotEmpty) ...[
                    _SectionHeader('Highlights'),
                    const SizedBox(height: 8),
                    ...tour.highlights.map((h) => _BulletItem(text: h, icon: Icons.star, color: Colors.amber)),
                    const SizedBox(height: 16),
                  ],

                  // ── What's included ──────────────────────────
                  if (tour.inclusions.isNotEmpty) ...[
                    _SectionHeader("What's Included"),
                    const SizedBox(height: 8),
                    ...tour.inclusions.map((i) => _BulletItem(text: i, icon: Icons.check_circle, color: AppTheme.primary)),
                    const SizedBox(height: 16),
                  ],

                  // ── What's not included ──────────────────────
                  if (tour.exclusions.isNotEmpty) ...[
                    _SectionHeader("Not Included"),
                    const SizedBox(height: 8),
                    ...tour.exclusions.map((e) => _BulletItem(text: e, icon: Icons.cancel, color: Colors.red)),
                    const SizedBox(height: 16),
                  ],

                  // ── Itinerary ────────────────────────────────
                  if (tour.itineraryDays.isNotEmpty) ...[
                    _SectionHeader('Itinerary'),
                    const SizedBox(height: 10),
                    ...tour.itineraryDays.map((day) => _ItineraryDay(day: day)),
                    const SizedBox(height: 16),
                  ] else if (tour.route != null) ...[
                    _SectionHeader('Route'),
                    const SizedBox(height: 8),
                    Text(tour.route!,
                        style: GoogleFonts.figtree(fontSize: 14, height: 1.5, color: Colors.black87)),
                    const SizedBox(height: 16),
                  ],

                  // ── Meeting point ────────────────────────────
                  if (tour.meetingPoint != null) ...[
                    _SectionHeader('Meeting Point'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(tour.meetingPoint!,
                              style: GoogleFonts.figtree(fontSize: 14, color: Colors.black87)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Languages ────────────────────────────────
                  if (tour.languages.isNotEmpty) ...[
                    _SectionHeader('Languages'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: tour.languages
                          .map((l) => Chip(
                                label: Text(l, style: GoogleFonts.figtree(fontSize: 12)),
                                backgroundColor: Colors.grey[100],
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 80), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar: price from + Book Tour CTA ───────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4))],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.45),
                      )),
                  Text(
                    widget.tour.pricePerPerson > 0
                        ? '₹${_formatPrice(widget.tour.pricePerPerson)}/person'
                        : 'On Request',
                    style: GoogleFonts.figtree(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _book,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.tour.pricePerPerson > 0 ? 'Book Tour' : 'Enquire on WhatsApp',
                    style: GoogleFonts.figtree(
                        fontSize: widget.tour.pricePerPerson > 0 ? 18 : 15,
                        fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // For priced tours → full BookingReviewScreen flow.
  // For Price On Request tours → WhatsApp enquiry (matching website behaviour).
  Future<void> _book() async {
    if (widget.tour.pricePerPerson > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingReviewScreen(tour: widget.tour),
        ),
      );
    } else {
      final title = Uri.encodeComponent(widget.tour.title);
      final uri = Uri.parse(
          'https://wa.me/919752377323?text=Hi%20Hoppity%2C%20I%20want%20to%20book%3A%20$title');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatPrice(double price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    return price.toStringAsFixed(0);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.black54),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: GoogleFonts.figtree(fontSize: 17, fontWeight: FontWeight.w700),
      );
}

class _BulletItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _BulletItem({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: GoogleFonts.figtree(fontSize: 14, height: 1.4))),
          ],
        ),
      );
}

class _ItineraryDay extends StatelessWidget {
  final ItineraryDay day;
  const _ItineraryDay({required this.day});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Center(
                child: Text('${day.day}',
                    style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.title, style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w700)),
                  if (day.description.isNotEmpty)
                    Text(day.description, style: GoogleFonts.figtree(fontSize: 13, color: Colors.black54, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}
