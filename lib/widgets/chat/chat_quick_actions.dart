import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/chat_provider.dart';

class ChatQuickActions extends StatelessWidget {
  const ChatQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.lightbulb_outline_rounded, 'Product Idea Generator', 'Help me generate a new e-commerce product idea.'),
      (Icons.search_rounded, 'Product Validation', 'I want to validate my product idea.'),
      (Icons.travel_explore_rounded, 'Product Research', 'I need to do product research for my store.'),
      (Icons.psychology_rounded, 'AI Decision Engine', 'Help me make a strategic decision for my store.'),
      (Icons.stacked_bar_chart_rounded, 'Competitor Analysis', 'Analyze competitors for my e-commerce store.'),
      (Icons.description_outlined, 'Business Plan Generator', 'Generate a business plan for my e-commerce store.'),
      (Icons.map_outlined, 'E-commerce Roadmap', 'Create a launch roadmap for my store.'),
      (Icons.rocket_launch_outlined, 'Store Launch Assistant', 'Help me launch my e-commerce store.'),
      (Icons.trending_up_rounded, 'Growth Coach', 'Act as my growth coach and help me scale my store.'),
      (Icons.memory_rounded, 'Business Memory', 'What do you remember about my store and business goals?'),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _QuickActionChip(
            icon: actions[index].$1,
            label: actions[index].$2,
            prompt: actions[index].$3,
          );
        },
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String prompt;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.prompt,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> {
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
          provider.inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.prompt.length),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF263248) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _hovered ? AppColors.lightCyan : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? AppColors.lightCyan : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
