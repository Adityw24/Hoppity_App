import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';       // PointerScrollEvent
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────
// AppResponsiveBuilder
// Use as MaterialApp.builder to make ALL routes responsive automatically.
// On mobile/narrow web → transparent pass-through.
// On wide web (>= 700px) → phone frame centred on a branded background.
// Auth screens (WelcomeScreen, SignInScreen, SignUpScreen) are passed
// their own floating-card treatment via their own layout, so we don't
// double-wrap them here.
// ─────────────────────────────────────────────────────────────────────
class AppResponsiveBuilder {
  static Widget build(BuildContext context, Widget? child) {
    if (!kIsWeb) return child ?? const SizedBox.shrink();

    final screenW = MediaQuery.of(context).size.width;
    if (screenW < 700) return child ?? const SizedBox.shrink();

    // Wide web: phone frame
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Center(
        child: Container(
          width: 402,
          height: MediaQuery.of(context).size.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 56,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// ResponsiveWrapper
// Used directly inside HomeScreen to add the web sidebar nav.
// The sidebar shows on web desktop alongside the phone frame.
// ─────────────────────────────────────────────────────────────────────
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final int navIndex;
  final ValueChanged<int>? onNavTap;
  final bool showNav;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.navIndex = 0,
    this.onNavTap,
    this.showNav = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final screenW = MediaQuery.of(context).size.width;
    if (screenW < 700) return child;

    // Wide web: sidebar + phone frame (sidebar sits outside the frame)
    // AppResponsiveBuilder already provides the frame via builder,
    // so here we only inject the sidebar alongside the child.
    return Stack(
      children: [
        // Sidebar floats left of the centred frame
        if (showNav && onNavTap != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 220,
            child: _WebSidebar(
              selectedIndex: navIndex,
              onTap: onNavTap!,
            ),
          ),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Web sidebar navigation
// ─────────────────────────────────────────────────────────────────────
class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _WebSidebar({
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded,      'Home'),
    (Icons.auto_awesome,      'For You'),
    (Icons.explore_outlined,  'Tours'),
    (Icons.people_outline,    'Community'),
    (Icons.person_outline,    'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 28),
            child: Text('Hoppity',
                style: GoogleFonts.figtree(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
          ),
          ..._items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final selected = selectedIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withOpacity(0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(item.$1,
                      color: selected
                          ? AppTheme.primary
                          : Colors.grey[600],
                      size: 21),
                  const SizedBox(width: 12),
                  Text(item.$2,
                      style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppTheme.primary
                              : Colors.grey[700])),
                ]),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text('Discover Real India',
                style: GoogleFonts.figtree(
                    fontSize: 11, color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// WebAwarePageView
// Wraps PageView with a mouse-wheel listener on web so the TikTok
// feed scrolls with a mouse. On mobile it's a transparent pass-through.
// ─────────────────────────────────────────────────────────────────────
class WebAwarePageView extends StatelessWidget {
  final PageController controller;
  final Axis scrollDirection;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;

  const WebAwarePageView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      onPageChanged: onPageChanged,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      physics: const PageScrollPhysics(),
    );

    if (!kIsWeb) return pageView;

    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent) {
          final currentPage = controller.page?.round() ?? 0;
          if (event.scrollDelta.dy > 0) {
            // Mouse wheel down → next
            controller.animateToPage(
              currentPage + 1,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
            );
          } else if (event.scrollDelta.dy < 0 && currentPage > 0) {
            // Mouse wheel up → previous
            controller.animateToPage(
              currentPage - 1,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      child: pageView,
    );
  }
}
