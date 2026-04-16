import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/tour.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';

// ─────────────────────────────────────────────────────────────
// TourFeedCard — full-screen TikTok-style card
// Media priority:
//   1. video_url present → VideoPlayer (mutable, auto-play on visible)
//   2. multiple images   → horizontal carousel with dot indicators
//   3. single image      → CachedNetworkImage full-bleed
// Only is_active=true itineraries reach this widget (filtered in TourService)
// ─────────────────────────────────────────────────────────────
class TourFeedCard extends StatefulWidget {
  final Tour tour;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const TourFeedCard({super.key, required this.tour, this.onTap, this.onBook});

  @override
  State<TourFeedCard> createState() => _TourFeedCardState();
}

class _TourFeedCardState extends State<TourFeedCard> {
  late bool _isLiked;
  late bool _isSaved;
  late int  _likes;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.tour.isLiked;
    _isSaved = widget.tour.isSaved;
    _likes   = widget.tour.likesCount;
  }

  @override
  Widget build(BuildContext context) {
    final size       = MediaQuery.of(context).size;
    final h          = size.height;
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final tour       = widget.tour;

    // Build ordered image list: cover first, then rest de-duped
    final images = _buildImageList(tour);

    return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── 1. Full-bleed media layer ──────────────────────
            _buildMedia(tour, images),

            // ── 2. Bottom gradient scrim ───────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.25, 0.65, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.92),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. Category chip — top-left ────────────────────
            Positioned(
              top: safeTop + 72, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Color(tour.categoryColor),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  tour.category,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ── 4. Right side action column ────────────────────
            Positioned(
              right: 12,
              bottom: safeBottom + 94,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like
                  _SideAction(
                    icon:  _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: _likes > 0 ? '$_likes' : '',
                    color: _isLiked ? Colors.red : Colors.white,
                    onTap: () => setState(() {
                      _isLiked = !_isLiked;
                      _likes  += _isLiked ? 1 : -1;
                    }),
                  ),
                  SizedBox(height: (h * 0.028).clamp(18.0, 26.0)),
                  // Comment
                  _SideAction(
                    icon:  Icons.chat_bubble_outline,
                    onTap: () {},
                  ),
                  SizedBox(height: (h * 0.028).clamp(18.0, 26.0)),
                  // Share
                  _SideAction(
                    icon:  Icons.send_outlined,
                    onTap: () async {
                      final text = Uri.encodeComponent(
                        'Check out "${tour.title}" on Hoppity! '
                        'https://hoppity.in/itinerary/${tour.id}',
                      );
                      final uri = Uri.parse('https://wa.me/?text=$text');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                  SizedBox(height: (h * 0.028).clamp(18.0, 26.0)),
                  // Save/Bookmark
                  _SideAction(
                    icon:  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? AppTheme.primary : Colors.white,
                    onTap: () async {
                      final next = !_isSaved;
                      setState(() => _isSaved = next);
                      if (next) {
                        await ProfileService.saveTour(tour.id);
                      } else {
                        await ProfileService.unsaveTour(tour.id);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── 5. Bottom info panel ───────────────────────────
            Positioned(
              left: 16, right: 72,
              bottom: safeBottom + 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guide row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: tour.guideAvatarUrl != null
                            ? CachedNetworkImageProvider(tour.guideAvatarUrl!)
                            : null,
                        child: tour.guideAvatarUrl == null
                            ? const Icon(Icons.person, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guide',
                              style: GoogleFonts.figtree(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (tour.guideName != null)
                            Text(
                              '@${tour.guideName!.toLowerCase().replaceAll(' ', '')}',
                              style: GoogleFonts.figtree(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: Colors.white70),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tour title
                  Text(
                    tour.title,
                    style: GoogleFonts.figtree(
                        fontSize: 24, fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Location + Duration
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(tour.location,
                            style: GoogleFonts.figtree(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: Colors.white70),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),

                  // Rating
                  if (tour.rating > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < tour.rating.round()
                              ? Icons.star : Icons.star_border,
                          color: Colors.amber, size: 14,
                        )),
                        const SizedBox(width: 4),
                        Text(
                          '${tour.rating} (${tour.reviewCount})',
                          style: GoogleFonts.figtree(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Price + Book CTA
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          tour.pricePerPerson > 0
                              ? '₹${_formatPrice(tour.pricePerPerson)}/person'
                              : 'On Request',
                          style: GoogleFonts.figtree(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── 6. Book Tour button — bottom right ─────────────────
            Positioned(
              right: 16,
              bottom: safeBottom + 20,
              child: GestureDetector(
                onTap: widget.onBook ?? widget.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Book Tour',
                    style: GoogleFonts.figtree(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  // ── Media builder: video → carousel → single image ──────────
  Widget _buildMedia(Tour tour, List<String> images) {
    // Priority 1: video
    if (tour.videoUrl != null && tour.videoUrl!.isNotEmpty) {
      return _VideoMedia(
        key: ValueKey('video_${tour.id}'),
        videoUrl: tour.videoUrl!,
        fallbackImage: images.isNotEmpty ? images.first : null,
      );
    }
    // Priority 2: image carousel (2+ images)
    if (images.length > 1) {
      return _ImageCarousel(
        key: ValueKey('carousel_${tour.id}'),
        images: images,
      );
    }
    // Priority 3: single image
    if (images.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: images.first,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.grey[900],
          child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.image_not_supported,
              color: Colors.white38, size: 48),
        ),
      );
    }
    return Container(color: Colors.grey[900]);
  }

  List<String> _buildImageList(Tour tour) {
    final all = <String>{};
    if (tour.coverImageUrl != null) all.add(tour.coverImageUrl!);
    all.addAll(tour.images);
    return all.toList();
  }

  String _formatPrice(double price) {
    if (price == 0) return 'On Request';
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    }
    return price.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────
// _VideoMedia — auto-plays when visible, pauses when scrolled away
// Falls back to image thumbnail while initialising or on error
// ─────────────────────────────────────────────────────────────
class _VideoMedia extends StatefulWidget {
  final String  videoUrl;
  final String? fallbackImage;
  const _VideoMedia({super.key, required this.videoUrl, this.fallbackImage});

  @override
  State<_VideoMedia> createState() => _VideoMediaState();
}

class _VideoMediaState extends State<_VideoMedia> {
  VideoPlayerController? _ctrl;
  bool _initialised = false;
  bool _error       = false;
  bool _muted       = false;
  bool _visible     = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(_muted ? 0 : 1);
      if (mounted) {
        setState(() { _ctrl = ctrl; _initialised = true; });
        if (_visible) ctrl.play();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _visible = info.visibleFraction > 0.5;
    if (_initialised && _ctrl != null) {
      _visible ? _ctrl!.play() : _ctrl!.pause();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? Key(widget.videoUrl),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or fallback
          if (_initialised && _ctrl != null && !_error)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:  _ctrl!.value.size.width,
                height: _ctrl!.value.size.height,
                child: VideoPlayer(_ctrl!),
              ),
            )
          else if (widget.fallbackImage != null)
            CachedNetworkImage(
              imageUrl: widget.fallbackImage!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[900]),
              errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
            )
          else
            Container(color: Colors.grey[900]),

          // Loading indicator
          if (!_initialised && !_error)
            const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2),
            ),

          // Mute / unmute button — top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 72, right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() => _muted = !_muted);
                _ctrl?.setVolume(_muted ? 0 : 1);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white, size: 20,
                ),
              ),
            ),
          ),

          // "VIDEO" badge — top left indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 72, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                  const SizedBox(width: 2),
                  Text('LIVE',
                      style: GoogleFonts.figtree(
                          fontSize: 10, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _ImageCarousel — swipeable horizontal images (Instagram-style)
// Dot indicator shows current position
// ─────────────────────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  const _ImageCarousel({super.key, required this.images});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Horizontal page view — swipe within the card
        // Uses a listener to intercept horizontal drags so vertical
        // page scrolling still works for the outer feed
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200 &&
                _current < widget.images.length - 1) {
              _controller.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut);
            } else if (details.primaryVelocity! > 200 && _current > 0) {
              _controller.previousPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut);
            }
          },
          child: PageView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: Colors.grey[900],
                    child: const Center(child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2))),
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.grey[900],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white38, size: 48)),
            ),
          ),
        ),

        // Dot indicators — bottom centre
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        // Image counter badge — top right
        Positioned(
          top: MediaQuery.of(context).padding.top + 72, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_current + 1}/${widget.images.length}',
              style: GoogleFonts.figtree(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),

        // Left/right tap zones for navigation
        Positioned(
          left: 0, top: 0, bottom: 120, width: 80,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _current > 0
                ? () => _controller.previousPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut)
                : null,
          ),
        ),
        Positioned(
          right: 0, top: 0, bottom: 120, width: 80,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _current < widget.images.length - 1
                ? () => _controller.nextPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut)
                : null,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SideAction — icon + optional label, right action column
// ─────────────────────────────────────────────────────────────
class _SideAction extends StatelessWidget {
  final IconData  icon;
  final String?   label;
  final Color     color;
  final VoidCallback onTap;

  const _SideAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(label!, style: GoogleFonts.figtree(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.0)),
          ],
        ],
      ),
    );
  }
}
