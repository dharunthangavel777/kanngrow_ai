import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';
import '../widgets/skeleton/app_startup_skeleton.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Splash Screen — auto-advances after animation completes
// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  final Widget? next;
  const SplashScreen({super.key, this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate immediately to optimize app load time if a next widget is provided
    if (widget.next != null) {
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.next!,
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      });
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
            top: -60, right: -60,
            child: _Glow(color: AppColors.lightCyan, size: 300, opacity: 0.10),
          ),
          Positioned(
            bottom: 0, left: -80,
            child: _Glow(color: const Color(0xFF5C2BE2), size: 260, opacity: 0.09),
          ),

          // Centre content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/logos/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 24),

              // Brand name
              const Text('Kangrow AI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8))
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.15, end: 0, duration: 500.ms),

              const SizedBox(height: 8),

              Text('Your E-Commerce Assistant',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 14,
                      letterSpacing: 0.2))
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 600.ms),
              
              const SizedBox(height: 48),
              
              const AppStartupSkeleton()
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ],
      ),
    );
  }
}

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
