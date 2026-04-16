import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette — matches hoppity.in website exactly ──────────
  static const Color primary       = Color(0xFF7C3AED); // #7c3aed violet-700
  static const Color primaryLight  = Color(0xFFA78BFA); // #a78bfa violet-400
  static const Color bgLight       = Color(0xFFF7F1FF); // #f7f1ff website bg
  static const Color primaryDark   = Color(0xFF5B21B6); // violet-800

  // ── Neutrals ─────────────────────────────────────────────────────
  static const Color black         = Color(0xFF000000);
  static const Color white         = Color(0xFFFFFFFF);
  static const Color navBackground = Color(0xFF1A1A1A);

  // ── Legacy aliases (kept so nothing breaks) ──────────────────────
  static const Color tagBackground = primary;
  static const Color cardOverlay   = Color(0x57000000);

  // ── Text styles (Figtree — matches Figma + website feel) ─────────
  static TextStyle get displayBold => GoogleFonts.figtree(
        fontSize: 26, fontWeight: FontWeight.w700, color: white);

  static TextStyle get titleBold => GoogleFonts.figtree(
        fontSize: 18, fontWeight: FontWeight.w700, color: white);

  static TextStyle get titleSemiBold => GoogleFonts.figtree(
        fontSize: 16, fontWeight: FontWeight.w600, color: white);

  static TextStyle get bodyBold => GoogleFonts.figtree(
        fontSize: 32, fontWeight: FontWeight.w700, color: black);

  static TextStyle get labelSemiBold => GoogleFonts.figtree(
        fontSize: 15, fontWeight: FontWeight.w600, color: white);

  static TextStyle get priceBold => GoogleFonts.figtree(
        fontSize: 13, fontWeight: FontWeight.w700, color: white);

  static TextStyle get usernameSemiBold => GoogleFonts.figtree(
        fontSize: 12, fontWeight: FontWeight.w600, color: white);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        textTheme: GoogleFonts.figtreeTextTheme(),
        scaffoldBackgroundColor: white,
        appBarTheme: AppBarTheme(
          backgroundColor: white,
          elevation: 0,
          titleTextStyle: GoogleFonts.figtree(
            fontSize: 18, fontWeight: FontWeight.w700, color: black),
        ),
      );
}
