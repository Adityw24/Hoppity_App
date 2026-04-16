import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'phone_auth_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const String _bgImage =
      'https://www.figma.com/api/mcp/asset/31fe78ad-68e7-47f2-ac22-c5683fb50abc';
  static const String _logoImage = 'assets/images/hoppity_logo1.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(CachedNetworkImageProvider(_bgImage), context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPassword() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset Password', style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter your email to receive a password reset link.', style: GoogleFonts.figtree(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'you@example.com', border: const OutlineInputBorder()),
            style: GoogleFonts.figtree(),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.figtree())),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await SupabaseService.sendPasswordReset(ctrl.text.trim());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reset link sent to \${ctrl.text.trim()}', style: GoogleFonts.figtree()),
                    backgroundColor: AppTheme.primary),
                );
              }
            },
            child: Text('Send Reset Link', style: GoogleFonts.figtree(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final ok = await SupabaseService.signInWithGoogle();
    if (!ok && mounted) {
      setState(() { _error = 'Google sign-in failed. Try again.'; _loading = false; });
    }
    // On success, Supabase auth state change navigates automatically
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
    // Web desktop: centred card on branded background
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
    // Mobile: full-screen with photo background
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // --- Background photo ---
        CachedNetworkImage(
          imageUrl: _bgImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        const ColoredBox(color: Color(0x33000000)),

        // --- Frosted glass overlay ---
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
                  Row(children: [
                    Expanded(
                      child: Text(
                        'WELCOME BACK',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Text(
                        'Sign in to continue your journey',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ]),
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

                  // Remember me + Forgot password
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        fillColor: WidgetStateProperty.all(Colors.white),
                        checkColor: AppTheme.primary,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      Text(
                        'Remember me',
                        style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _showForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
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

                  // Sign In button
                  _GlassButton(
                    label: 'Sign In',
                    loading: _loading,
                    onTap: _signIn,
                  ),
                  const SizedBox(height: 20),

                  // Or divider
                  Text('Or', style: GoogleFonts.figtree(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 20),

                  // Continue with Google
                  _GlassButton(
                    label: 'Continue with Google',
                    icon: CachedNetworkImage(
                      imageUrl: 'https://www.figma.com/api/mcp/asset/6021b5fd-b9dd-4771-b87d-e4043114715e',
                      width: 18,
                      height: 18,
                    ),
                    onTap: _signInWithGoogle,
                  ),
                  const SizedBox(height: 14),

                  // Continue with Phone
                  _GlassButton(
                    label: 'Continue with Phone',
                    icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneAuthScreen(isSignIn: true)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                        child: Text(
                          'Sign up',
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

// --- Reusable frosted glass text field ---
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
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.figtree(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.figtree(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          prefixIcon: Icon(icon, color: Colors.black54, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// --- Reusable frosted glass button ---
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
