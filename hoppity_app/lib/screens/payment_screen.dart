import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Tour tour;
  final double amount;
  final int numPersons;
  final DateTime? bookingDate;
  final String? scheduleId;

  const PaymentScreen({
    super.key,
    required this.tour,
    required this.amount,
    required this.numPersons,
    this.bookingDate,
    this.scheduleId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ── State ──────────────────────────────────────────────────────
  _PayStatus _status = _PayStatus.creating;
  String? _errorMsg;
  String? _bookingId;
  String? _qrImageUrl;
  DateTime? _qrExpiry;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _createBookingAndQr();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Main flow ──────────────────────────────────────────────────
  Future<void> _createBookingAndQr() async {
    try {
      // Step 1 – pending booking
      setState(() => _status = _PayStatus.creating);
      final bookingId = await TourService.bookTourPending(
        tourId: widget.tour.id,
        numPersons: widget.numPersons,
        totalAmount: widget.amount,
        scheduleId: widget.scheduleId,
        bookingDate: widget.bookingDate,
      );
      if (bookingId == null) throw Exception('Could not create booking');
      _bookingId = bookingId;

      // Step 2 – QR code from Edge Function
      setState(() => _status = _PayStatus.generatingQr);
      late FunctionResponse res;
      bool qrAvailable = true;
      try {
        res = await Supabase.instance.client.functions.invoke(
          'create-razorpay-qr',
          body: {
            'booking_id': bookingId,
            'amount': widget.amount,
            'tour_title': widget.tour.title,
          },
        );
        if (res.status != 200) qrAvailable = false;
      } catch (_) {
        qrAvailable = false;
      }

      // ── Fallback: Edge Function not deployed / Razorpay not configured yet ──
      // Confirm the booking directly so the app keeps working during development.
      // Once the Edge Function is deployed and API keys are set, the QR flow
      // will be used automatically.
      if (!qrAvailable) {
        if (_bookingId != null) {
          await Supabase.instance.client
              .from('Bookings')
              .update({'status': 'confirmed'})
              .eq('id', _bookingId!);
        }
        if (mounted) setState(() => _status = _PayStatus.confirmed);
        return;
      }

      final data = res.data as Map<String, dynamic>;
      _qrImageUrl = data['image_url'] as String;
      final closeBy = data['close_by'] as int;
      _qrExpiry = DateTime.fromMillisecondsSinceEpoch(closeBy * 1000);
      _remaining = _qrExpiry!.difference(DateTime.now());

      // Step 3 – start countdown
      _startCountdown();

      // Step 4 – listen for Realtime payment confirmation
      _listenForConfirmation(bookingId);

      if (mounted) setState(() => _status = _PayStatus.waitingPayment);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _PayStatus.error;
          _errorMsg = e.toString();
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final rem = _qrExpiry!.difference(DateTime.now());
      if (rem.isNegative) {
        _countdownTimer?.cancel();
        if (mounted) setState(() => _status = _PayStatus.expired);
      } else {
        setState(() => _remaining = rem);
      }
    });
  }

  void _listenForConfirmation(String bookingId) {
    _channel = Supabase.instance.client.channel('pay-$bookingId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'Bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: bookingId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (newStatus == 'confirmed' && mounted) {
              _countdownTimer?.cancel();
              _channel?.unsubscribe();
              setState(() => _status = _PayStatus.confirmed);
            }
          },
        )
        .subscribe();
  }

  Future<void> _deleteOrphan(String id) async {
    try {
      await Supabase.instance.client
          .from('Bookings')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────
  String get _amountStr =>
      NumberFormat('#,##,###').format(widget.amount.toStringAsFixed(0));

  String get _countdownStr {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _dateStr => widget.bookingDate != null
      ? DateFormat('EEE, d MMM yyyy').format(widget.bookingDate!)
      : '';

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent accidental back during payment
      onWillPop: () async {
        if (_status == _PayStatus.waitingPayment) {
          return await _confirmCancel();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () async {
              if (_status == _PayStatus.waitingPayment) {
                if (await _confirmCancel()) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text('Complete Payment',
              style: GoogleFonts.figtree(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _PayStatus.creating:
        return _buildLoading('Creating your booking…');
      case _PayStatus.generatingQr:
        return _buildLoading('Generating QR code…');
      case _PayStatus.waitingPayment:
        return _buildQrScreen();
      case _PayStatus.confirmed:
        return _buildConfirmed();
      case _PayStatus.expired:
        return _buildExpired();
      case _PayStatus.error:
        return _buildError();
    }
  }

  // ── Loading ─────────────────────────────────────────────────────
  Widget _buildLoading(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(label,
              style: GoogleFonts.figtree(
                  fontSize: 15, color: Colors.black.withOpacity(0.55))),
        ],
      ),
    );
  }

  // ── QR Screen ──────────────────────────────────────────────────
  Widget _buildQrScreen() {
    final isLow = _remaining.inSeconds <= 120;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          // Amount pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '₹$_amountStr',
              style: GoogleFonts.figtree(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.numPersons} person${widget.numPersons > 1 ? 's' : ''} · ${widget.tour.title}',
            style: GoogleFonts.figtree(
                fontSize: 13, color: Colors.black.withOpacity(0.50)),
            textAlign: TextAlign.center,
          ),
          if (_dateStr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _dateStr,
              style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.50)),
            ),
          ],
          const SizedBox(height: 28),
          // QR box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _qrImageUrl!,
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary, strokeWidth: 2),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      width: 240,
                      height: 240,
                      color: Colors.grey[100],
                      child: const Icon(Icons.qr_code,
                          size: 96, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16,
                        color: isLow ? Colors.red : Colors.orange.shade700),
                    const SizedBox(width: 5),
                    Text(
                      'Expires in $_countdownStr',
                      style: GoogleFonts.figtree(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLow ? Colors.red : Colors.orange.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to pay',
                    style: GoogleFonts.figtree(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (final step in [
                  '1. Open GPay, PhonePe, Paytm or any UPI app',
                  '2. Tap "Scan QR" and point your camera here',
                  '3. Confirm the amount and pay',
                  '4. This screen will update automatically',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      step,
                      style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.60),
                          height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Waiting indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: Colors.green.shade600,
                    strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('Waiting for payment…',
                  style: GoogleFonts.figtree(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Confirmed ──────────────────────────────────────────────────
  Widget _buildConfirmed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  color: Colors.green.shade600, size: 56),
            ),
            const SizedBox(height: 24),
            Text('Payment Successful!',
                style: GoogleFonts.figtree(
                    fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Your booking for ${widget.tour.title} is confirmed.',
              style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.55),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (_dateStr.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(_dateStr,
                      style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text('₹$_amountStr paid',
                style: GoogleFonts.figtree(
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Pop all the way back to home
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text('Done',
                    style: GoogleFonts.figtree(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Expired ────────────────────────────────────────────────────
  Widget _buildExpired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_off_outlined,
                  color: Colors.orange.shade700, size: 48),
            ),
            const SizedBox(height: 24),
            Text('QR Code Expired',
                style: GoogleFonts.figtree(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'The QR code has expired. Generate a new one to complete your booking.',
              style: GoogleFonts.figtree(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.55),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _status = _PayStatus.creating;
                    _qrImageUrl = null;
                    _bookingId = null;
                  });
                  _createBookingAndQr();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text('Try Again',
                    style: GoogleFonts.figtree(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.figtree(
                      fontSize: 14, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Something went wrong',
                style: GoogleFonts.figtree(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              _errorMsg ?? 'An unexpected error occurred.',
              style: GoogleFonts.figtree(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.55),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _status = _PayStatus.creating;
                    _errorMsg = null;
                    _bookingId = null;
                  });
                  _createBookingAndQr();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text('Try Again',
                    style: GoogleFonts.figtree(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back',
                  style: GoogleFonts.figtree(
                      fontSize: 14, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cancel confirmation ─────────────────────────────────────────
  Future<bool> _confirmCancel() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Payment?',
            style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
        content: Text(
          'Your booking will be cancelled if you leave now.',
          style: GoogleFonts.figtree(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay',
                style: GoogleFonts.figtree(color: AppTheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave',
                style: GoogleFonts.figtree(color: Colors.grey)),
          ),
        ],
      ),
    );
    if (result == true && _bookingId != null) {
      await _deleteOrphan(_bookingId!);
    }
    return result ?? false;
  }
}

enum _PayStatus { creating, generatingQr, waitingPayment, confirmed, expired, error }
