import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.borderDark, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightCyan.withOpacity(0.15),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 36)),
            ),
          )
              .animate()
              .shimmer(duration: 1000.ms, color: AppColors.lightCyan.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            'Hi, Dharun! 👋',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 400.ms,
                delay: 100.ms,
              ),
          const SizedBox(height: 8),
          Text(
            'Your AI E-Commerce Assistant is ready.\nWhat shall we sell today?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 32),
          _buildSuggestionGrid(),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildSuggestionGrid() {
    final suggestions = [
      ('💡', 'Product Idea', 'Generate a product idea for me'),
      ('✅', 'Validate Product', 'Help me validate my product'),
      ('🗺️', 'Launch Roadmap', 'Create a 6-week launch plan'),
      ('📈', 'Marketing', 'Build a go-to-market strategy'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: suggestions
          .asMap()
          .entries
          .map(
            (entry) => _SuggestionChip(
              emoji: entry.value.$1,
              label: entry.value.$2,
              delay: entry.key * 100,
            ),
          )
          .toList(),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String emoji;
  final String label;
  final int delay;

  const _SuggestionChip({
    required this.emoji,
    required this.label,
    required this.delay,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? AppColors.lightCyan.withValues(alpha: 0.5) : AppColors.borderDark,
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.lightCyan.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _hovered ? AppColors.lightCyan : AppColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 300 + widget.delay))
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: Duration(milliseconds: 300 + widget.delay));
  }
}
