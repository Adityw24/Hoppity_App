import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';

class ForYouCard extends StatefulWidget {
  final RecommendedTour tour;
  final VoidCallback onViewDetails;
  final VoidCallback onBookNow;

  const ForYouCard({
    super.key,
    required this.tour,
    required this.onViewDetails,
    required this.onBookNow,
  });

  @override
  State<ForYouCard> createState() => _ForYouCardState();
}

class _ForYouCardState extends State<ForYouCard> {
  // Track dwell time for ML signal
  DateTime? _viewStart;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _viewStart = DateTime.now();
  }

  @override
  void dispose() {
    _logDwell();
    super.dispose();
  }

  void _logDwell() {
    if (_viewStart == null) return;
    final ms = DateTime.now().difference(_viewStart!).inMilliseconds;
    if (ms > 500) {
      RecommendationService.logEvent(
        eventType: 'view',
        tourId: widget.tour.id,
        category: widget.tour.category,
        location: widget.tour.state,
        dwellMs: ms,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;

    // Figma card: white bg, 0.25 opacity border, 10px radius, 364×568px
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
          // ── Hero image + tag overlay ───────────────────────
          Stack(
            children: [
              // Image — Figma: 349×214px, 10px radius
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: tour.primaryImage != null
                    ? CachedNetworkImage(
                        imageUrl: tour.primaryImage!,
                        width: double.infinity,
                        height: 214,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 214,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary, strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 214,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                      )
                    : Container(height: 214, color: Colors.grey[200]),
              ),

              // "For You" pill — Figma: white bg, top-left, 11px SemiBold
              Positioned(
                top: 10,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tour.isExplore ? 'Discover' : 'For You',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // Save button — top-right action
              Positioned(
                top: 10,
                right: 14,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isSaved = !_isSaved);
                    RecommendationService.logEvent(
                      eventType: _isSaved ? 'swipe_save' : 'swipe_skip',
                      tourId: tour.id,
                      category: tour.category,
                    );
                  },
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSaved ? Icons.favorite : Icons.favorite_border,
                      color: _isSaved ? Colors.red : Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title — Figma: 20px SemiBold ──────────────
                Text(
                  tour.title,
                  style: GoogleFonts.figtree(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // ── Location — Figma: pin + 15px 35% opacity ──
                Row(children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.black.withOpacity(0.45)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      tour.location,
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.35),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Duration chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tour.durationDisplay,
                      style: GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),

                // ── AI reason text — Figma: 15px SemiBold 50% opacity ──
                Text(
                  tour.reasonText,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.50),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // ── Price — Figma: 15px bold ───────────────────
                Text(
                  tour.pricePerPerson > 0
                      ? '₹${_fmt(tour.pricePerPerson)}/person'
                      : 'On Request',
                  style: GoogleFonts.figtree(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Divider ───────────────────────────────────
                Divider(color: Colors.black.withOpacity(0.12), height: 1),
                const SizedBox(height: 10),

                // ── Guide row — Figma: 40px avatar + 16px bold name ──
                Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: tour.guideAvatarUrl != null
                        ? CachedNetworkImageProvider(tour.guideAvatarUrl!)
                        : null,
                    child: tour.guideAvatarUrl == null
                        ? const Icon(Icons.person, size: 18, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour.guideName ?? 'Certified Guide',
                          style: GoogleFonts.figtree(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (tour.rating > 0)
                          Row(children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < tour.rating.round() ? Icons.star : Icons.star_border,
                                size: 11,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text('${tour.rating}',
                                style: GoogleFonts.figtree(
                                    fontSize: 11, color: Colors.grey)),
                          ]),
                      ],
                    ),
                  ),
                  // Difficulty chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(tour.difficultyColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tour.difficulty,
                      style: GoogleFonts.figtree(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(tour.difficultyColor),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Highlight tags — Figma: dark 8% pills ─────
                if (tour.highlights.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tour.highlights
                        .take(3)
                        .map((h) => _TagChip(h))
                        .toList(),
                  ),
                const SizedBox(height: 14),

                // ── Dual CTAs — Figma: View Details (outlined) + Book Now (black) ──
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        RecommendationService.logEvent(
                          eventType: 'tap',
                          tourId: tour.id,
                          category: tour.category,
                          metadata: {'action': 'view_details'},
                        );
                        widget.onViewDetails();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.black.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View Details',
                          style: GoogleFonts.figtree(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        RecommendationService.logEvent(
                          eventType: 'tap',
                          tourId: tour.id,
                          category: tour.category,
                          metadata: {'action': 'book_now'},
                        );
                        widget.onBookNow();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Book Now',
                          style: GoogleFonts.figtree(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) {
    if (price == 0) return 'On Request';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    return price.toStringAsFixed(0);
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.length > 15 ? '${label.substring(0, 13)}…' : label,
          style: GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
}
