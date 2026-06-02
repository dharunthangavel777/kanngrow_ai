import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_theme.dart';
import 'auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding data
// ─────────────────────────────────────────────────────────────────────────────
class _Page {
  final String svgPath;
  final Color accentColor;
  final String title;
  final String subtitle;
  const _Page({
    required this.svgPath,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });
}

const _pages = [
  _Page(
    svgPath: 'assets/onboarding_screen/1.svg',
    accentColor: AppColors.lightCyan,
    title: 'Idea Generator',
    subtitle:
        'Enter budget & interests — get tailored e-commerce product ideas',
  ),
  _Page(
    svgPath: 'assets/onboarding_screen/2.svg',
    accentColor: AppColors.lightCyan,
    title: 'Idea Validation',
    subtitle: 'Market demand, competition & risk scored instantly',
  ),
  _Page(
    svgPath: 'assets/onboarding_screen/3.svg',
    accentColor: AppColors.lightCyan,
    title: 'E-Commerce Chat',
    subtitle:
        'Ask anything — vendors, sourcing, marketing — answered for your store',
  ),
  _Page(
    svgPath: 'assets/onboarding_screen/4.svg',
    accentColor: AppColors.lightCyan,
    title: 'Business Memory',
    subtitle:
        'Remembers your store, industry, goals & decisions — no repetition',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Screen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Animated background glow (changes with page)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: -40,
            right: -40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    page.accentColor.withValues(alpha: 0.12),
                    page.accentColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                    child: GestureDetector(
                      onTap: _goToAuth,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnboardPage(page: _pages[i]),
                  ),
                ),

                // Dots + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? page.accentColor
                                  : Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 28),

                      // CTA button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: page.accentColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: page.accentColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _current == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single onboarding page
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardPage extends StatelessWidget {
  final _Page page;
  const _OnboardPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG Illustration with a soft ambient background glow behind it
          SizedBox(
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient glow behind the illustration
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: page.accentColor.withValues(alpha: 0.15),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // The actual SVG illustration colored entirely white
                    SvgPicture.asset(
                      page.svgPath,
                      height: 240,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (BuildContext context) =>
                          const Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 500.ms),

          const SizedBox(height: 48),

          Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              )
              .animate(key: ValueKey('${page.title}_title'))
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),

          const SizedBox(height: 16),

          Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              )
              .animate(key: ValueKey('${page.title}_subtitle'))
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),
        ],
      ),
    );
  }
}
