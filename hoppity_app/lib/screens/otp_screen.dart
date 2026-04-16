import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────
// OtpScreen
// Step 2 of 2 in the phone OTP flow.
// Six individual digit boxes with auto-advance and backspace handling.
// 60-second countdown timer → Resend button appears after expiry.
// Auto-submits when all 6 digits are entered.
// ─────────────────────────────────────────────────────────────
class OtpScreen extends StatefulWidget {
  final String phone; // E.164 format: +919876543210

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _timerSeconds = 60;

  static const _bgImage =
      'https://www.figma.com/api/mcp/asset/31fe78ad-68e7-47f2-ac22-c5683fb50abc';
  static const _logoImage = 'assets/images/hoppity_logo1.png';

  // One controller + focus node per digit
  final _controllers = List.generate(
    _otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(
    _otpLength, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _secondsLeft = _timerSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // Called after each digit entry
  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) return;
    // Move forward
    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last box filled — remove focus + try to verify
      _focusNodes[index].unfocus();
      if (_otp.length == _otpLength) _verify();
    }
  }

  // Called on backspace with empty field — move backward
  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _verify() async {
    if (_otp.length < _otpLength) {
      setState(() => _error = 'Enter all 6 digits.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.verifyPhoneOtp(
        phone: widget.phone,
        otp: _otp,
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on AuthException catch (e) {
      _clearBoxes();
      setState(() => _error = _friendlyError(e.message));
    } catch (_) {
      _clearBoxes();
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await SupabaseService.sendPhoneOtp(widget.phone);
      _clearBoxes();
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('OTP resent to ${widget.phone}',
            style: GoogleFonts.figtree()),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      setState(() => _error = 'Could not resend OTP. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    if (mounted) _focusNodes[0].requestFocus();
  }

  String _friendlyError(String raw) {
    if (raw.contains('expired')) return 'OTP has expired. Tap Resend to get a new one.';
    if (raw.contains('Invalid') || raw.contains('invalid'))
      return 'Incorrect OTP. Please check and try again.';
    return raw;
  }

  // Formatted phone for display: +91 98765 43210
  String get _maskedPhone {
    final p = widget.phone;
    if (p.length > 7) {
      // Show country code + last 4 digits, mask the rest
      final code = p.substring(0, p.length - 10).isEmpty
          ? p.substring(0, 3)
          : p.substring(0, p.length - 10);
      final last4 = p.substring(p.length - 4);
      return '$code ••••••$last4';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_bgImage, fit: BoxFit.cover),
          const ColoredBox(color: Color(0x44000000)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Image.asset(_logoImage, width: 72, height: 72),
                  const SizedBox(height: 24),

                  Text('VERIFY OTP',
                    style: GoogleFonts.figtree(
                      fontSize: 30, fontWeight: FontWeight.w800,
                      color: Colors.black)),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to\n$_maskedPhone',
                    style: GoogleFonts.figtree(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // ── 6 OTP boxes ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_otpLength, (i) {
                      return Padding(
                        padding: EdgeInsets.only(right: i < _otpLength - 1 ? 10 : 0),
                        child: _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (v) => _onDigitChanged(i, v),
                          onKeyEvent: (e) => _onKeyEvent(i, e),
                        ),
                      );
                    }),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(_error!,
                        style: GoogleFonts.figtree(
                          fontSize: 13, color: Colors.red.shade200),
                        textAlign: TextAlign.center),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Verify button ────────────────────────────
                  GestureDetector(
                    onTap: _loading ? null : _verify,
                    child: Container(
                      height: 52,
                      width: 240,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                          : Center(
                              child: Text('Verify & Continue',
                                style: GoogleFonts.figtree(
                                  fontSize: 17, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Timer + Resend ───────────────────────────
                  if (_secondsLeft > 0)
                    Text(
                      'Resend OTP in ${_secondsLeft}s',
                      style: GoogleFonts.figtree(
                        fontSize: 14, color: Colors.white.withOpacity(0.70)),
                    )
                  else
                    GestureDetector(
                      onTap: _resending ? null : _resend,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4)),
                        ),
                        child: _resending
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh,
                                    color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Resend OTP',
                                    style: GoogleFonts.figtree(
                                      fontSize: 14, color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Wrong number
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Wrong number? Go back',
                      style: GoogleFonts.figtree(
                        fontSize: 13, color: Colors.white.withOpacity(0.65),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.45))),
                  ),

                  const SizedBox(height: 24),
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
// Single OTP digit box
// ─────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (_, __) {
          final focused = focusNode.hasFocus;
          return Container(
            width: 46,
            height: 56,
            decoration: BoxDecoration(
              color: focused
                  ? Colors.white.withOpacity(0.95)
                  : Colors.white.withOpacity(0.30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused ? AppTheme.primary : Colors.white.withOpacity(0.5),
                width: focused ? 2 : 1,
              ),
              boxShadow: focused
                  ? [BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.figtree(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: focused ? AppTheme.primary : Colors.black,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }
}
