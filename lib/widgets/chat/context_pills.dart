import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/chat_provider.dart';

class ContextPills extends StatelessWidget {
  const ContextPills({super.key});

  @override
  Widget build(BuildContext context) {
    final pills = [
      (Icons.lightbulb_outline_rounded, 'Product Idea',
          'Give me a trending product idea'),
      (Icons.check_circle_outline_rounded, 'Validate Idea',
          'Help me validate my e-commerce product idea'),
      (Icons.rocket_launch_outlined, 'Launch Plan',
          'Create a 6-week launch roadmap for my store'),
      (Icons.trending_up_rounded, 'Marketing',
          'Build a go-to-market strategy for my store'),
      (Icons.shopping_cart_rounded, 'Sourcing',
          'What\'s the best vendor sourcing strategy?'),
    ];

    return Container(
      color: AppColors.bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pills
              .map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PillChip(icon: p.$1, label: p.$2, prompt: p.$3),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _PillChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String prompt;

  const _PillChip({required this.icon, required this.label, required this.prompt});

  @override
  State<_PillChip> createState() => _PillChipState();
}

class _PillChipState extends State<_PillChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          context.read<ChatProvider>().sendMessage(widget.prompt);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.cardBg
                : AppColors.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? AppColors.lightCyan.withOpacity(0.6)
                  : AppColors.borderDark,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.lightCyan.withOpacity(0.1),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: AppColors.lightCyan,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.lightCyan,
                  fontSize: 12,
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
