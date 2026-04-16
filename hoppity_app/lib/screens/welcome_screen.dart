import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'phone_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _bgImage =
      'https://www.figma.com/api/mcp/asset/49088a43-c5bf-42c3-b951-9dbbc146ee95';
  static const _logoImage = 'assets/images/hoppity_logo1.png';

  @override
  Widget build(BuildContext context) {
    // Web wide: show a centred auth card instead of full-bleed photo
    if (kIsWeb && MediaQuery.of(context).size.width >= 700) {
      return _WebWelcome(
        onSignIn: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SignInScreen())),
        onSignUp: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SignUpScreen())),
      );
    }

    // Mobile / narrow web: full-bleed photo layout
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_bgImage, fit: BoxFit.cover),
          const ColoredBox(color: Color(0x33000000)),

          // Bottom sheet — grows to cover home indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenH * 0.42 + safeBottom,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('WELCOME',
                          style: GoogleFonts.figtree(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(
                        'Explore your favourite journey',
                        style: GoogleFonts.figtree(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.62)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const SignInScreen())),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              elevation: 0),
                          child: Text('Sign In',
                              style: GoogleFonts.figtree(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen())),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              shape: const StadiumBorder()),
                          child: Text('Sign up',
                              style: GoogleFonts.figtree(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const PhoneAuthScreen())),
                          icon: const Icon(Icons.phone_outlined, size: 20),
                          label: Text('Continue with Phone',
                              style: GoogleFonts.figtree(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(color: AppTheme.primary),
                              shape: const StadiumBorder()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Logo
          Positioned(
            top: screenH * 0.14,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(_logoImage,
                  width: 160, height: 160, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

/// Web desktop welcome — centred auth card on branded background
class _WebWelcome extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  static const _logoImage = 'assets/images/hoppity_logo1.png';

  const _WebWelcome({required this.onSignIn, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 40,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(_logoImage, width: 80, height: 80),
              const SizedBox(height: 20),
              Text('WELCOME',
                  style: GoogleFonts.figtree(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
              const SizedBox(height: 8),
              Text('Explore your favourite journey',
                  style: GoogleFonts.figtree(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.55)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onSignIn,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0),
                  child: Text('Sign In',
                      style: GoogleFonts.figtree(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onSignUp,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: const StadiumBorder()),
                  child: Text('Sign up',
                      style: GoogleFonts.figtree(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
