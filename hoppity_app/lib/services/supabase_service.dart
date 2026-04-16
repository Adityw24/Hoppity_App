import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ── Auth: Sign up with email ─────────────────────────────────
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // ── Auth: Sign in with email ─────────────────────────────────
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Auth: Google OAuth ───────────────────────────────────────
  static Future<bool> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.hoppity://login-callback',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Auth: Forgot password ────────────────────────────────────
  static Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.hoppity://reset-callback',
    );
  }

  // ── Auth: Sign out ───────────────────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Auth: Current user ───────────────────────────────────────
  static User? get currentUser => _client.auth.currentUser;

  // ── Auth: Stream ─────────────────────────────────────────────
  static Stream<AuthState> get authStream => _client.auth.onAuthStateChange;

  // ── Auth: Send OTP to phone number ──────────────────────────
  // phone must be E.164 format: +919876543210
  // Supabase sends the SMS via the configured provider (Twilio)
  static Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  // ── Auth: Verify OTP and sign in ─────────────────────────────
  // Returns the session on success; throws AuthException on wrong OTP
  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
  }
}
