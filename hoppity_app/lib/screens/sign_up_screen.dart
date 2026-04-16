import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';
import 'phone_auth_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String _bgImage =
      'https://www.figma.com/api/mcp/asset/eb6a67ef-2b77-46dc-afd8-a039a43e139b';
  static const String _logoImage = 'assets/images/hoppity_logo1.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeTerms = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Terms & Conditions', style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            'By creating an account you agree to Hoppity\'s terms of service. '
            'Your personal data is processed in accordance with our Privacy Policy. '
            'You agree not to misuse the platform or share false information. '
            'Bookings are subject to individual tour cancellation policies.\n\n'
            'For full terms visit hoppity.in/terms',
            style: GoogleFonts.figtree(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.figtree(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _loading = true);
    final ok = await SupabaseService.signInWithGoogle();
    if (!ok && mounted) {
      setState(() { _error = 'Google sign-up failed. Try again.'; _loading = false; });
    }
  }

  Future<void> _signUp() async {
    if (!_agreeTerms) {
      setState(() => _error = 'Please agree to the terms and conditions.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: '',
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Something went wrong. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && MediaQuery.of(context).size.width >= 700) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Center(
          child: Container(
            width: 420,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildBody(),
          ),
        ),
      );
    }
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background photo
        Image.network(_bgImage, fit: BoxFit.cover),
        const ColoredBox(color: Color(0x33000000)),

        // Frosted glass overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
          ),
          child: const SizedBox.expand(),
        ),

        SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Logo
                  Image.asset(_logoImage, width: 85, height: 85),
                  const SizedBox(height: 20),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create an Account!',
                      style: GoogleFonts.figtree(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign up to start your journey',
                      style: GoogleFonts.figtree(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email field
                  _GlassField(
                    controller: _emailController,
                    hint: 'Email Id',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  _GlassField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Terms checkbox row
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeTerms,
                        onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                        fillColor: WidgetStateProperty.all(Colors.white.withOpacity(0.8)),
                        checkColor: Colors.black,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      Text(
                        'Agree with ',
                        style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: _showTerms,
                        child: Text(
                          'terms and condition.',
                          style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                      ),
                    ],
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),

                  // Sign Up button
                  _GlassButton(
                    label: 'Sign Up',
                    loading: _loading,
                    onTap: _signUp,
                  ),
                  const SizedBox(height: 20),

                  // Or divider
                  Text('Or', style: GoogleFonts.figtree(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 20),

                  // Continue with Google
                  _GlassButton(
                    label: 'Continue with Google',
                    icon: Image.network(
                      'https://www.figma.com/api/mcp/asset/c932ba00-63df-4b3d-bf5a-27251098845a',
                      width: 18,
                      height: 18,
                    ),
                    onTap: _signUpWithGoogle,
                  ),
                  const SizedBox(height: 14),

                  // Continue with Phone
                  _GlassButton(
                    label: 'Continue with Phone',
                    icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneAuthScreen(isSignIn: false)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.30),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.figtree(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xB2595959)),
          prefixIcon: Icon(icon, color: Colors.black54, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final Widget? icon;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        width: 266,
        decoration: BoxDecoration(
          color: const Color(0x806F6F6F),
          borderRadius: BorderRadius.circular(40),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [const Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
