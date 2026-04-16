import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';

// ─────────────────────────────────────────────────────────────
// PhoneAuthScreen
// Step 1 of 2 in the phone OTP flow.
// User selects country code and enters their mobile number.
// Tapping "Send OTP" calls Supabase → SMS is sent → pushes OtpScreen.
// ─────────────────────────────────────────────────────────────

// Common country codes — India first, then alphabetical
const _countryCodes = [
  _Country(flag: '🇮🇳', name: 'India',          code: '+91',  digits: 10),
  _Country(flag: '🇦🇺', name: 'Australia',       code: '+61',  digits: 9),
  _Country(flag: '🇧🇩', name: 'Bangladesh',      code: '+880', digits: 10),
  _Country(flag: '🇨🇦', name: 'Canada',          code: '+1',   digits: 10),
  _Country(flag: '🇫🇷', name: 'France',          code: '+33',  digits: 9),
  _Country(flag: '🇩🇪', name: 'Germany',         code: '+49',  digits: 11),
  _Country(flag: '🇮🇩', name: 'Indonesia',       code: '+62',  digits: 11),
  _Country(flag: '🇲🇾', name: 'Malaysia',        code: '+60',  digits: 10),
  _Country(flag: '🇳🇵', name: 'Nepal',           code: '+977', digits: 10),
  _Country(flag: '🇳🇿', name: 'New Zealand',     code: '+64',  digits: 9),
  _Country(flag: '🇵🇰', name: 'Pakistan',        code: '+92',  digits: 10),
  _Country(flag: '🇵🇭', name: 'Philippines',     code: '+63',  digits: 10),
  _Country(flag: '🇸🇬', name: 'Singapore',       code: '+65',  digits: 8),
  _Country(flag: '🇱🇰', name: 'Sri Lanka',       code: '+94',  digits: 9),
  _Country(flag: '🇦🇪', name: 'UAE',             code: '+971', digits: 9),
  _Country(flag: '🇬🇧', name: 'United Kingdom',  code: '+44',  digits: 10),
  _Country(flag: '🇺🇸', name: 'United States',   code: '+1',   digits: 10),
];

class _Country {
  final String flag;
  final String name;
  final String code;
  final int digits;
  const _Country({
    required this.flag,
    required this.name,
    required this.code,
    required this.digits,
  });
}

class PhoneAuthScreen extends StatefulWidget {
  // true = "sign in" mode, false = "sign up" mode
  // Supabase phone OTP works identically for both — it upserts the user.
  final bool isSignIn;
  const PhoneAuthScreen({super.key, this.isSignIn = true});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  _Country _country = _countryCodes.first; // India default
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _bgImage =
      'https://www.figma.com/api/mcp/asset/31fe78ad-68e7-47f2-ac22-c5683fb50abc';
  static const _logoImage = 'assets/images/hoppity_logo1.png';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '${_country.code}${_phoneCtrl.text.trim()}';

  Future<void> _sendOtp() async {
    final number = _phoneCtrl.text.trim();
    if (number.isEmpty) {
      setState(() => _error = 'Please enter your phone number.');
      return;
    }
    if (number.length < _country.digits) {
      setState(() => _error =
          'Enter a valid ${_country.digits}-digit number for ${_country.name}.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.sendPhoneOtp(_fullPhone);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(phone: _fullPhone),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('rate limit') || raw.contains('too many'))
      return 'Too many attempts. Please wait a minute and try again.';
    if (raw.contains('invalid') || raw.contains('Invalid'))
      return 'Invalid phone number. Check the number and country code.';
    if (raw.contains('phone provider')) {
      return 'Phone auth not yet enabled. Please contact support or use email/Google.';
    }
    return 'Could not send OTP. Please try again.';
  }

  void _pickCountry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              )),
            const SizedBox(height: 16),
            Text('Select Country',
              style: GoogleFonts.figtree(
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _countryCodes.length,
                itemBuilder: (_, i) {
                  final c = _countryCodes[i];
                  final selected = c.code == _country.code && c.name == _country.name;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(c.name,
                      style: GoogleFonts.figtree(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                    trailing: Text(c.code,
                      style: GoogleFonts.figtree(
                        color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    selected: selected,
                    selectedTileColor: AppTheme.primary.withOpacity(0.06),
                    onTap: () {
                      setState(() => _country = c);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Center(child: Image.asset(_logoImage, width: 80, height: 80)),
                  const SizedBox(height: 24),

                  Text(
                    widget.isSignIn ? 'SIGN IN' : 'JOIN HOPPITY',
                    style: GoogleFonts.figtree(
                      fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your mobile number to receive a one-time passcode',
                    style: GoogleFonts.figtree(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 32),

                  // ── Phone field ──────────────────────────────
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        // Country code picker
                        GestureDetector(
                          onTap: _pickCountry,
                          child: Container(
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_country.flag,
                                  style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 4),
                                Text(_country.code,
                                  style: GoogleFonts.figtree(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.black54, size: 18),
                              ],
                            ),
                          ),
                        ),

                        // Divider
                        Container(width: 1, height: 36, color: Colors.black26),

                        // Number input
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_country.digits),
                            ],
                            style: GoogleFonts.figtree(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: Colors.black),
                            decoration: InputDecoration(
                              hintText: '98765 43210',
                              hintStyle: GoogleFonts.figtree(
                                fontSize: 16, fontWeight: FontWeight.w600,
                                color: Colors.black38),
                              border: InputBorder.none,
                              contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(_error!,
                        style: GoogleFonts.figtree(
                          fontSize: 13, color: Colors.red.shade200)),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Send OTP button ──────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _loading ? null : _sendOtp,
                      child: Container(
                        height: 52,
                        width: 260,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 16, offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.sms_outlined,
                                    color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Send OTP',
                                    style: GoogleFonts.figtree(
                                      fontSize: 18, fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'We\'ll send a 6-digit code to ${_country.code} XXXXXX${_phoneCtrl.text.isEmpty ? "XXXX" : _phoneCtrl.text.substring((_phoneCtrl.text.length - 4).clamp(0, _phoneCtrl.text.length))}',
                      style: GoogleFonts.figtree(
                        fontSize: 12, color: Colors.white.withOpacity(0.65)),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Alt auth divider ─────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or use',
                        style: GoogleFonts.figtree(
                          fontSize: 13, color: Colors.white.withOpacity(0.65))),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                  ]),
                  const SizedBox(height: 20),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.email_outlined,
                        color: Colors.white, size: 16),
                      label: Text('Email & Password',
                        style: GoogleFonts.figtree(
                          fontSize: 14, color: Colors.white,
                          fontWeight: FontWeight.w600)),
                    ),
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
