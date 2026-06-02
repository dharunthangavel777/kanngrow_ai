import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../app_theme.dart';
import 'setup/dynamic_onboarding_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth Screen
// ─────────────────────────────────────────────────────────────────────────────
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _handleAuth(BuildContext context, String provider) async {
    if (provider == 'Google') {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        await FirebaseAuth.instance.signInWithCredential(credential);

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DynamicOnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (_) => false,
        );
      } catch (e) {
        debugPrint('Google Sign-In Error: $e');
      }
    } else {
      // Apple sign in placeholder
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DynamicOnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background glows
          Positioned(
            top: -80,
            left: -80,
            child: _Glow(color: AppColors.lightCyan, size: 320, opacity: 0.08),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _Glow(
              color: const Color(0xFF5C2BE2),
              size: 280,
              opacity: 0.08,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // ── SVG Illustration ─────────────────────────────────
                    SvgPicture.asset(
                          'assets/auth_screen/auth.svg',
                          height: 220,
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (_) => const SizedBox(
                            height: 220,
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.lightCyan,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: 32),

                    // ── Headline ─────────────────────────────────────────
                    Column(
                      children: [
                        const Text(
                              'Welcome to Kangrow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.8,
                              ),
                            )
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.1, end: 0, duration: 400.ms),

                        const SizedBox(height: 8),

                        Text(
                          'Sign in to build your store with AI',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // ── Auth buttons ─────────────────────────────────────
                    Column(
                          children: [
                            // Continue with Google
                            _AuthButton(
                              onTap: () => _handleAuth(context, 'Google'),
                              icon: _GoogleIcon(),
                              label: 'Continue with Google',
                              delay: 0,
                            ),

                            // ── Or divider ───────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      'Or',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Continue with Apple
                            _AuthButton(
                              onTap: () => _handleAuth(context, 'Apple'),
                              icon: const Icon(
                                Icons.apple_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: 'Continue with Apple',
                              delay: 80,
                              dark: true,
                            ),
                          ],
                        )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),

                    const SizedBox(height: 24),

                    // ── Terms & Conditions ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: AppColors.lightCyan,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.lightCyan,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showTerms(context),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppColors.lightCyan,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.lightCyan,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showPrivacy(context),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ).animate(delay: 650.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) =>
      _showSheet(context, 'Terms of Service', _termsText);
  void _showPrivacy(BuildContext context) =>
      _showSheet(context, 'Privacy Policy', _privacyText);

  void _showSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LegalSheet(title: title, body: body),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth button
// ─────────────────────────────────────────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final bool dark;
  final int delay;
  const _AuthButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.dark = false,
    this.delay = 0,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: widget.dark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.dark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icon,
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.dark ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google icon (SVG-like using Canvas)
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _GooglePainter(size: 22);
  }
}

class _GooglePainter extends StatelessWidget {
  final double size;
  const _GooglePainter({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Blue arc (top-right to bottom)
    _arc(canvas, cx, cy, r, -0.52, 2.3, const Color(0xFF4285F4));
    // Red arc (top-left)
    _arc(canvas, cx, cy, r, 3.79, 1.05, const Color(0xFFEA4335));
    // Yellow arc (bottom)
    _arc(canvas, cx, cy, r, 2.09, 0.97, const Color(0xFFFBBC05));
    // Green arc (left)
    _arc(canvas, cx, cy, r, 3.14, 0.65, const Color(0xFF34A853));

    // White centre
    canvas.drawCircle(Offset(cx, cy), r * 0.45, Paint()..color = Colors.white);

    // Blue right stripe
    final p = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.22, r, r * 0.44), p);
    canvas.drawCircle(Offset(cx, cy), r * 0.45, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.22, r * 0.55, r * 0.44),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  void _arc(
    Canvas c,
    double cx,
    double cy,
    double r,
    double start,
    double sweep,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = r * 0.38
      ..style = PaintingStyle.stroke;
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.81),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LegalSheet extends StatelessWidget {
  final String title;
  final String body;
  const _LegalSheet({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
            // Body
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal copy
// ─────────────────────────────────────────────────────────────────────────────
const _termsText = '''
Last updated: May 2025

1. Acceptance of Terms
By accessing or using Kangrow AI, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.

2. Use of Service
Kangrow AI is provided for personal and professional use to assist sellers in building and growing their stores. You agree not to misuse the service, including using it for unlawful purposes.

3. Account Responsibility
You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account.

4. Intellectual Property
All content, designs, and AI models within Kangrow AI are the intellectual property of Kangrow AI Inc. You may not copy, reproduce, or distribute any part of the service without explicit written permission.

5. Limitation of Liability
Kangrow AI provides information and recommendations as-is. We are not liable for any business decisions made based on AI-generated advice.

6. Modifications
We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms.

7. Contact
For questions about these terms, contact us at legal@kangrow.ai
''';

const _privacyText = '''
Last updated: May 2025

1. Information We Collect
We collect information you provide directly, including your name, email address, and usage data generated while using Kangrow AI.

2. How We Use Your Information
Your data is used to personalise your AI experience, improve our models, and provide customer support. We do not sell your personal data to third parties.

3. AI Memory
With your consent, Kangrow AI stores context from your conversations to provide personalised, continuous assistance. You can delete this data at any time from your profile settings.

4. Data Security
We implement industry-standard security measures to protect your data. All data is encrypted in transit and at rest.

5. Third-Party Services
We use trusted third-party services (e.g., Google Sign-In, Apple Sign-In) for authentication. Their privacy policies apply to data processed by those services.

6. Your Rights
You have the right to access, correct, or delete your personal data at any time by contacting us at privacy@kangrow.ai.

7. Contact
For privacy-related inquiries, contact us at privacy@kangrow.ai
''';

// ─────────────────────────────────────────────────────────────────────────────
// Glow helper
// ─────────────────────────────────────────────────────────────────────────────
class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _Glow({required this.color, required this.size, required this.opacity});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.2, 1.0],
        ),
      ),
    );
  }
}
