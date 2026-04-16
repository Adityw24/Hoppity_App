import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tour.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final Tour tour;
  const BookingReviewScreen({super.key, required this.tour});

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  // ── State ──────────────────────────────────────────────────────
  int _numPersons = 1;
  DateTime? _selectedDate;
  String? _selectedScheduleId;
  List<Map<String, dynamic>> _schedules = [];
  bool _loadingSchedules = true;
  bool _booking = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    try {
      final res = await Supabase.instance.client
          .from('Tour_Schedules')
          .select()
          .eq('tour_id', widget.tour.id)
          .eq('status', 'available')
          .gte('date', DateTime.now().toIso8601String().substring(0, 10))
          .order('date')
          .limit(12);
      if (mounted) {
        setState(() {
          _schedules = (res as List).cast<Map<String, dynamic>>();
          _loadingSchedules = false;
          // Pre-select first available
          if (_schedules.isNotEmpty) {
            _selectedScheduleId = _schedules.first['id'] as String;
            _selectedDate = DateTime.parse(_schedules.first['date'] as String);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSchedules = false);
    }
  }

  double get _pricePerPerson => widget.tour.pricePerPerson;
  double get _subtotal => _pricePerPerson * _numPersons;
  double get _platformFee => (_subtotal * 0.03).roundToDouble();
  double get _total => _subtotal + _platformFee;

  int _availableSpots(String scheduleId) {
    final s = _schedules.firstWhere(
      (s) => s['id'] == scheduleId,
      orElse: () => {},
    );
    if (s.isEmpty) return widget.tour.maxGroupSize;
    return ((s['available_spots'] as int? ?? 0) -
            (s['booked_spots'] as int? ?? 0))
        .clamp(0, widget.tour.maxGroupSize);
  }

  void _confirmBooking() {
    if (_selectedDate == null && _schedules.isNotEmpty) {
      _showSnack('Please select a date');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          tour: widget.tour,
          amount: _total,
          numPersons: _numPersons,
          bookingDate: _selectedDate,
          scheduleId: _selectedScheduleId,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.figtree()),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final tour = widget.tour;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Review & Confirm',
            style: GoogleFonts.figtree(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.fromLTRB(16, 8, 16, 100 + safeBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tour summary card (Figma: thumbnail + name + price) ─
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.black.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: tour.primaryImage != null
                        ? CachedNetworkImage(
                            imageUrl: tour.primaryImage!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 76, height: 76, color: Colors.grey[200],
                              child: const Icon(Icons.broken_image_outlined,
                                  size: 28, color: Colors.grey)),
                          )
                        : Container(
                            width: 76,
                            height: 76,
                            color: Colors.grey[200]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                Color(tour.categoryColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tour.category,
                              style: GoogleFonts.figtree(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(tour.categoryColor))),
                        ),
                        const SizedBox(height: 5),
                        Text(tour.title,
                            style: GoogleFonts.figtree(
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(tour.location,
                              style: GoogleFonts.figtree(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(tour.durationDisplay,
                              style: GoogleFonts.figtree(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Date selection ─────────────────────────────────────
            _SectionLabel('Select Date'),
            const SizedBox(height: 10),
            _loadingSchedules
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2))
                : _schedules.isEmpty
                    ? _buildFreeDatePicker()
                    : _buildSchedulePicker(),
            const SizedBox(height: 24),

            // ── Group size ─────────────────────────────────────────
            _SectionLabel('Number of People'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Text('Travellers',
                      style: GoogleFonts.figtree(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  // Decrease
                  GestureDetector(
                    onTap: () {
                      if (_numPersons > 1) {
                        setState(() => _numPersons--);
                      }
                    },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.black.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text('$_numPersons',
                        style: GoogleFonts.figtree(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  // Increase
                  GestureDetector(
                    onTap: () {
                      final maxSpots = _selectedScheduleId != null
                          ? _availableSpots(_selectedScheduleId!)
                          : tour.maxGroupSize;
                      if (_numPersons < maxSpots) {
                        setState(() => _numPersons++);
                      }
                    },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Max group note
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                'Max ${tour.maxGroupSize} people · '
                '${_selectedScheduleId != null ? _availableSpots(_selectedScheduleId!) : tour.maxGroupSize} spots available',
                style: GoogleFonts.figtree(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.40)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Special requests ───────────────────────────────────
            _SectionLabel('Special Requests (optional)'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: GoogleFonts.figtree(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Dietary requirements, accessibility needs, questions...',
                hintStyle: GoogleFonts.figtree(
                    fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Price breakdown (priced) / enquiry card (On Request) ──
            if (tour.pricePerPerson > 0) ...[
              _SectionLabel('Price Breakdown'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label:
                          '₹${_formatNum(_pricePerPerson)} × $_numPersons person${_numPersons > 1 ? 's' : ''}',
                      value: '₹${_formatNum(_subtotal)}',
                    ),
                    const SizedBox(height: 10),
                    _PriceRow(
                      label: 'Platform fee (3%)',
                      value: '₹${_formatNum(_platformFee)}',
                      muted: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                          color: Colors.black.withOpacity(0.10), height: 1),
                    ),
                    _PriceRow(
                      label: 'Total',
                      value: '₹${_formatNum(_total)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Price On Request',
                          style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'This tour is priced based on your group size, travel dates, '
                      "and customisation. Message us on WhatsApp and we'll reply within a few hours.",
                      style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.65),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── What's included ────────────────────────────────────
            if (tour.inclusions.isNotEmpty) ...[
              _SectionLabel("What's Included"),
              const SizedBox(height: 8),
              ...tour.inclusions.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item,
                              style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.75))),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // ── Meeting point ──────────────────────────────────────
            if (tour.meetingPoint != null) ...[
              _SectionLabel('Meeting Point'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tour.meetingPoint!,
                          style: GoogleFonts.figtree(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.75))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Cancellation note ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free cancellation up to 48 hours before the tour date.',
                      style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom CTA bar ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: widget.tour.pricePerPerson > 0
              // ── Priced tour: show total + confirm button ──────────
              ? Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: GoogleFonts.figtree(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.50))),
                        Text('₹${_formatNum(_total)}',
                            style: GoogleFonts.figtree(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _booking ? null : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: _booking
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('Confirm Booking',
                                  style: GoogleFonts.figtree(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                )
              // ── On Request tour: WhatsApp enquiry button ──────────
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final title = Uri.encodeComponent(widget.tour.title);
                      final persons = _numPersons;
                      final date = _selectedDate != null
                          ? Uri.encodeComponent(
                              ' on ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}')
                          : '';
                      final uri = Uri.parse(
                          'https://wa.me/919752377323?text=Hi%20Hoppity%2C%20I%20want%20to%20enquire%20about%3A%20$title$date%20for%20$persons%20person${persons > 1 ? 's' : ''}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.chat, size: 20),
                    label: Text('Enquire on WhatsApp',
                        style: GoogleFonts.figtree(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp green
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Schedule date selector (chips for available slots) ─────────
  Widget _buildSchedulePicker() {
    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _schedules.length,
        itemBuilder: (_, i) {
          final s = _schedules[i];
          final date = DateTime.parse(s['date'] as String);
          final id = s['id'] as String;
          final spots = ((s['available_spots'] as int? ?? 0) -
                  (s['booked_spots'] as int? ?? 0))
              .clamp(0, 99);
          final selected = _selectedScheduleId == id;
          final full = spots == 0;

          return GestureDetector(
            onTap: full
                ? null
                : () => setState(() {
                      _selectedScheduleId = id;
                      _selectedDate = date;
                      // Clamp persons to available spots
                      if (_numPersons > spots) _numPersons = spots;
                    }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: full
                    ? Colors.grey[100]
                    : selected
                        ? Colors.black
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: full
                      ? Colors.grey[300]!
                      : selected
                          ? Colors.black
                          : Colors.black.withOpacity(0.15),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('d MMM').format(date),
                      style: GoogleFonts.figtree(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: full
                              ? Colors.grey
                              : selected
                                  ? Colors.white
                                  : Colors.black)),
                  const SizedBox(height: 2),
                  Text(
                    full ? 'Full' : '$spots left',
                    style: GoogleFonts.figtree(
                        fontSize: 10,
                        color: full
                            ? Colors.grey
                            : selected
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.45)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Free-form date picker when no schedules ────────────────────
  Widget _buildFreeDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              DateTime.now().add(const Duration(days: 7)),
          firstDate:
              DateTime.now().add(const Duration(days: 1)),
          lastDate:
              DateTime.now().add(const Duration(days: 365)),
          builder: (_, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedDate != null
                ? AppTheme.primary
                : Colors.black.withOpacity(0.10),
            width: _selectedDate != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18,
                color: _selectedDate != null
                    ? AppTheme.primary
                    : Colors.black.withOpacity(0.40)),
            const SizedBox(width: 10),
            Text(
              _selectedDate != null
                  ? DateFormat('EEE, d MMMM yyyy').format(_selectedDate!)
                  : 'Choose a date',
              style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: _selectedDate != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _selectedDate != null
                      ? Colors.black
                      : Colors.black.withOpacity(0.40)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatNum(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.truncate() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return n.toStringAsFixed(0);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.figtree(
          fontSize: 16, fontWeight: FontWeight.w700));
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool muted;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: GoogleFonts.figtree(
                  fontSize: bold ? 15 : 14,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w500,
                  color: muted
                      ? Colors.black.withOpacity(0.45)
                      : Colors.black)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.figtree(
                  fontSize: bold ? 16 : 14,
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? Colors.black : Colors.black.withOpacity(0.75))),
        ],
      );
}
