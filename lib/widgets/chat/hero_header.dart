import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import 'hero_suggestions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main hero header
// ─────────────────────────────────────────────────────────────────────────────
class HeroHeader extends StatelessWidget {
  final bool isWide;

  const HeroHeader({
    super.key,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: _ExpandedContent(isWide: isWide),
          ),
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Space for overlay ChatHeader
            const SizedBox(height: 60),
    
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
        ),
      ),
    );
  }
}
