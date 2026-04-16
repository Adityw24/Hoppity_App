import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  /// When true, hides the AppBar back button (used inside ProfileScreen tabs).
  /// When false (default), shows back button for standalone push navigation.
  final bool embedded;
  const MyBookingsScreen({super.key, this.embedded = false});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bookings = await ProfileService.fetchMyTrips();
    if (mounted) setState(() { _bookings = bookings; _loading = false; });
  }

  List<Map<String, dynamic>> get _upcoming => _bookings.where((b) {
        final d = b['booking_date'];
        if (d == null) return b['status'] == 'confirmed';
        return DateTime.parse(d as String).isAfter(DateTime.now()) &&
            b['status'] == 'confirmed';
      }).toList();

  List<Map<String, dynamic>> get _past => _bookings.where((b) {
        final d = b['booking_date'];
        if (d == null) return b['status'] == 'completed';
        return DateTime.parse(d as String).isBefore(DateTime.now()) ||
            b['status'] == 'completed';
      }).toList();

  List<Map<String, dynamic>> get _cancelled =>
      _bookings.where((b) => b['status'] == 'cancelled').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Hide back button when embedded in ProfileScreen tab
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text('My Bookings',
            style: GoogleFonts.figtree(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.figtree(fontWeight: FontWeight.w500, fontSize: 13),
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          tabs: [
            Tab(text: 'Upcoming (${_upcoming.length})'),
            Tab(text: 'Past (${_past.length})'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _BookingList(
                  bookings: _upcoming,
                  emptyIcon: Icons.upcoming_outlined,
                  emptyText: 'No upcoming tours',
                  emptySubtext: 'Book a guided tour to get started',
                  onRefresh: _load,
                  showCancelOption: true,
                  onCancel: _cancelBooking,
                ),
                _BookingList(
                  bookings: _past,
                  emptyIcon: Icons.history_outlined,
                  emptyText: 'No past tours yet',
                  emptySubtext: 'Your completed tours will appear here',
                  onRefresh: _load,
                  showReviewOption: true,
                  onReview: _openReviewSheet,
                ),
                _BookingList(
                  bookings: _cancelled,
                  emptyIcon: Icons.cancel_outlined,
                  emptyText: 'No cancelled bookings',
                  onRefresh: _load,
                ),
              ],
            ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Booking',
            style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to cancel? You may be eligible for a refund if cancelled 48+ hours before the tour.',
          style: GoogleFonts.figtree(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Booking',
                style: GoogleFonts.figtree(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel Tour',
                style: GoogleFonts.figtree(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client
          .from('Bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      await _load();
    }
  }

  void _openReviewSheet(Map<String, dynamic> booking) {
    final tour = booking['Itineraries'] as Map<String, dynamic>?;
    if (tour == null) return;

    int _rating = 5;
    final _reviewCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              Text('Rate your experience',
                  style: GoogleFonts.figtree(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(tour['title'] as String? ?? 'Tour',
                  style: GoogleFonts.figtree(
                      fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              // Star selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setS(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewCtrl,
                maxLines: 4,
                style: GoogleFonts.figtree(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Share your experience with other travellers...',
                  hintStyle: GoogleFonts.figtree(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await TourService.submitReview(
                      tourId: tour['id'].toString(),
                      rating: _rating,
                      text: _reviewCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Review submitted — thank you!',
                            style: GoogleFonts.figtree()),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: const StadiumBorder(),
                      elevation: 0),
                  child: Text('Submit Review',
                      style: GoogleFonts.figtree(
                          color: Colors.white, fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Booking list tab content
// ─────────────────────────────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final IconData emptyIcon;
  final String emptyText;
  final String? emptySubtext;
  final Future<void> Function() onRefresh;
  final bool showCancelOption;
  final bool showReviewOption;
  final void Function(String bookingId)? onCancel;
  final void Function(Map<String, dynamic> booking)? onReview;

  const _BookingList({
    required this.bookings,
    required this.emptyIcon,
    required this.emptyText,
    this.emptySubtext,
    required this.onRefresh,
    this.showCancelOption = false,
    this.showReviewOption = false,
    this.onCancel,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(emptyText,
                  style: GoogleFonts.figtree(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              if (emptySubtext != null) ...[
                const SizedBox(height: 6),
                Text(emptySubtext!,
                    style: GoogleFonts.figtree(
                        fontSize: 13, color: Colors.grey[400]),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(
          booking: bookings[i],
          showCancelOption: showCancelOption,
          showReviewOption: showReviewOption,
          onCancel: onCancel,
          onReview: onReview,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool showCancelOption;
  final bool showReviewOption;
  final void Function(String)? onCancel;
  final void Function(Map<String, dynamic>)? onReview;

  const _BookingCard({
    required this.booking,
    this.showCancelOption = false,
    this.showReviewOption = false,
    this.onCancel,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final tour = booking['Itineraries'] as Map<String, dynamic>?;
    final status = booking['status'] as String? ?? 'confirmed';
    final date = booking['booking_date'] as String?;
    final persons = (booking['num_persons'] as int?) ?? 1;
    final total = booking['total_amount'];

    final statusColor = {
      'confirmed': AppTheme.primary,
      'completed': Colors.blue,
      'cancelled': Colors.red,
    }[status] ?? Colors.grey;

    final statusLabel = {
      'confirmed': 'Confirmed',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    }[status] ?? status;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tour info row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: tour?['cover_image_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: tour!['cover_image_url'] as String,
                          width: 72, height: 72, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 72, height: 72, color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_outlined,
                                size: 28, color: Colors.grey)))
                      : Container(
                          width: 72, height: 72, color: Colors.grey[200]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tour?['title'] as String? ?? 'Tour',
                          style: GoogleFonts.figtree(
                              fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      if (tour?['location'] != null)
                        Row(children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(tour!['location'] as String,
                              style: GoogleFonts.figtree(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                      const SizedBox(height: 5),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(statusLabel,
                            style: GoogleFonts.figtree(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.calendar_today_outlined,
                      label: date != null
                          ? DateFormat('d MMM yyyy')
                              .format(DateTime.parse(date))
                          : 'Date TBD',
                    ),
                    const SizedBox(width: 10),
                    _DetailChip(
                      icon: Icons.people_outline,
                      label: '$persons person${persons > 1 ? 's' : ''}',
                    ),
                    const Spacer(),
                    if (total != null)
                      Text(
                        '₹${_fmt(double.tryParse(total.toString()) ?? 0)}',
                        style: GoogleFonts.figtree(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
                // Action buttons
                if (showCancelOption || showReviewOption) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (showReviewOption)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onReview?.call(booking),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text('Leave Review',
                                style: GoogleFonts.figtree(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      if (showCancelOption) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              onCancel?.call(booking['id'] as String),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade400),
                          child: Text('Cancel',
                              style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double n) {
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '₹${n.toStringAsFixed(0)}';
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.black.withOpacity(0.40)),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.figtree(
              fontSize: 12, color: Colors.black.withOpacity(0.60))),
    ],
  );
}
