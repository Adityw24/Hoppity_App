import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tour.dart';

enum ItineraryCardStyle { grid, list }

class ItineraryCard extends StatelessWidget {
  final Tour tour;
  final VoidCallback onTap;
  final ItineraryCardStyle style;

  const ItineraryCard({
    super.key,
    required this.tour,
    required this.onTap,
    this.style = ItineraryCardStyle.grid,
  });

  @override
  Widget build(BuildContext context) {
    return style == ItineraryCardStyle.grid
        ? _GridCard(tour: tour, onTap: onTap)
        : _ListCard(tour: tour, onTap: onTap);
  }
}

// ─────────────────────────────────────────────────────────────
// GRID CARD — 2-column, image-led, matches Figma Search Page
// ─────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final Tour tour;
  final VoidCallback onTap;
  const _GridCard({required this.tour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = Color(tour.categoryColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image with overlays ───────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: tour.primaryImage != null
                      ? CachedNetworkImage(
                          imageUrl: tour.primaryImage!,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _ImageSkeleton(h: 130),
                          errorWidget: (_, __, ___) =>
                              _ImageSkeleton(h: 130),
                        )
                      : _ImageSkeleton(h: 130),
                ),
                // Category chip — top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: _CategoryChip(
                    label: tour.category,
                    color: catColor,
                  ),
                ),
                // Rating — top right
                if (tour.rating > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            tour.rating.toStringAsFixed(1),
                            style: GoogleFonts.figtree(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Difficulty badge — bottom left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(tour.difficultyColor).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tour.difficulty,
                      style: GoogleFonts.figtree(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Text content ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    tour.title,
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Location
                  Row(children: [
                    Icon(Icons.location_on,
                        size: 11,
                        color: Colors.black.withOpacity(0.40)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        tour.location,
                        style: GoogleFonts.figtree(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.40),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Duration + Price row
                  Row(
                    children: [
                      _DurationChip(label: tour.durationDisplay),
                      const Spacer(),
                      Text(
                        _formatPrice(tour.pricePerPerson),
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p == 0) return 'On Request';
    if (p >= 1000) {
      return '₹${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}K/p';
    }
    return '₹${p.toStringAsFixed(0)}/p';
  }
}

// ─────────────────────────────────────────────────────────────
// LIST CARD — full-width, more detail visible at a glance
// ─────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final Tour tour;
  final VoidCallback onTap;
  const _ListCard({required this.tour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = Color(tour.categoryColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
              child: Stack(
                children: [
                  tour.primaryImage != null
                      ? CachedNetworkImage(
                          imageUrl: tour.primaryImage!,
                          width: 110,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _ImageSkeleton(h: 120, w: 110),
                          errorWidget: (_, __, ___) =>
                              _ImageSkeleton(h: 120, w: 110),
                        )
                      : _ImageSkeleton(h: 120, w: 110),
                  // Category chip
                  Positioned(
                    top: 6, left: 6,
                    child: _CategoryChip(
                        label: tour.category, color: catColor, small: true),
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + rating row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tour.title,
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tour.rating > 0) ...[
                          const SizedBox(width: 6),
                          Row(children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              tour.rating.toStringAsFixed(1),
                              style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(children: [
                      Icon(Icons.location_on,
                          size: 11,
                          color: Colors.black.withOpacity(0.40)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          tour.location,
                          style: GoogleFonts.figtree(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.40),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    // Description excerpt
                    if (tour.description != null)
                      Text(
                        tour.description!,
                        style: GoogleFonts.figtree(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.55),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Duration · Difficulty · Price
                    Row(children: [
                      _DurationChip(label: tour.durationDisplay),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(tour.difficultyColor)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
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
                      const Spacer(),
                      Text(
                        _formatPrice(tour.pricePerPerson),
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p == 0) return 'On Request';
    if (p >= 1000) {
      return '₹${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}K';
    }
    return '₹${p.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _CategoryChip(
      {required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: small ? 9 : 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

class _DurationChip extends StatelessWidget {
  final String label;
  const _DurationChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.access_time,
              size: 10, color: Colors.black.withOpacity(0.50)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
        ]),
      );
}

class _ImageSkeleton extends StatelessWidget {
  final double h;
  final double? w;
  const _ImageSkeleton({required this.h, this.w});

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        color: Colors.grey[200],
        child: const Icon(Icons.landscape_outlined,
            color: Colors.grey, size: 28),
      );
}
