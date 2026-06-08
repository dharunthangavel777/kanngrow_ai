import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/chat_provider.dart';

// Suggestion prompts shown inside hero header when no messages
class HeroSuggestionGrid extends StatelessWidget {
  const HeroSuggestionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      (Icons.lightbulb_outline_rounded, 'Product Idea',
          'Give me a trending product idea'),
      (Icons.check_circle_outline_rounded, 'Validate Idea',
          'Help me validate my e-commerce product idea'),
      (Icons.rocket_launch_outlined, 'Launch Plan',
          'Create a 6-week launch roadmap for my store'),
      (Icons.trending_up_rounded, 'Marketing',
          'Build a go-to-market strategy for my store'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions
          .asMap()
          .entries
          .map(
            (e) => _SuggestionPill(
              icon: e.value.$1,
              label: e.value.$2,
              prompt: e.value.$3,
              delay: e.key * 80,
            ),
          )
          .toList(),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 500.ms);
  }
}

class _SuggestionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final String prompt;
  final int delay;

  const _SuggestionPill({
    required this.icon,
    required this.label,
    required this.prompt,
    required this.delay,
  });

  @override
  State<_SuggestionPill> createState() => _SuggestionPillState();
}

class _SuggestionPillState extends State<_SuggestionPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          final provider = context.read<ChatProvider>();
          provider.inputController.text = widget.prompt;
          // Move cursor to the end of the text
          provider.inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.prompt.length),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.lightCyan.withValues(alpha: 0.1)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered
                  ? AppColors.lightCyan.withValues(alpha: 0.4)
                  : AppColors.borderDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 14,
                  color: _hovered ? AppColors.lightCyan : Colors.white70),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? AppColors.lightCyan : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: 600 + widget.delay),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 350.ms,
          delay: Duration(milliseconds: 600 + widget.delay),
        );
  }
}
