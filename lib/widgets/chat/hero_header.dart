import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../screens/profile_screen.dart';
import 'hero_suggestions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main hero header
// ─────────────────────────────────────────────────────────────────────────────
class HeroHeader extends StatelessWidget {
  final bool isCollapsed;
  final bool isWide;

  const HeroHeader({
    super.key,
    required this.isCollapsed,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Glow blobs removed for clean modern look ──────────────────────

          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: isCollapsed
                ? _CollapsedBar(isWide: isWide)
                : _ExpandedContent(isWide: isWide),
          ),
        ],
      ),
    );
  }
}

// Glow layer removed
// Collapsed bar — minimal sticky header while chatting
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsedBar extends StatelessWidget {
  final bool isWide;
  const _CollapsedBar({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => _GlassBtn(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.lightCyan,
                        AppColors.lightCyanHover
                      ]),
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/logos/logo.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Kangrow AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          _ProfileAvatar(size: 34),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded content — full immersive hero
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandedContent extends StatelessWidget {
  final bool isWide;
  const _ExpandedContent({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top nav ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              if (!isWide)
                Builder(
                  builder: (ctx) => _GlassBtn(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              const Spacer(),
              _ProfileAvatar(size: 38),
            ],
          ),
        ),

        // ── Spacer pushes content to vertical centre ──────────────────
        const Spacer(),

        // ── Central hero content ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'Kangrow AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI Entrepreneur Partner',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 700.ms, delay: 100.ms)
            .slideY(begin: 0.06, end: 0, duration: 600.ms, delay: 100.ms),

        const SizedBox(height: 28),

        // ── Suggestion chips ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const HeroSuggestionGrid(),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 300.ms)
            .slideY(begin: 0.06, end: 0, duration: 500.ms, delay: 300.ms),

        const Spacer(),

        // ── Subtle bottom label ───────────────────────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Powered by Claude Sonnet · GPT-4o',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



class _ProfileAvatar extends StatelessWidget {
  final double size;
  const _ProfileAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [AppColors.lightCyan, AppColors.lightCyanHover]),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightCyan.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text('D',
              style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ),
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}

