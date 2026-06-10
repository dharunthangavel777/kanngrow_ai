import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../screens/app_settings_screens.dart';

class ChatQuickActions extends StatelessWidget {
  const ChatQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const SizedBox.shrink();
    }

    final actionDefinitions = [
      (Icons.lightbulb_outline_rounded, 'Product Idea Generator', 'Help me generate a new e-commerce product idea.', null),
      (Icons.search_rounded, 'Product Validation', 'I want to validate my product idea.', null),
      (Icons.travel_explore_rounded, 'Product Research', 'I need to do product research for my store.', 'trendAnalysis'),
      (Icons.psychology_rounded, 'AI Decision Engine', 'Help me make a strategic decision for my store.', null),
      (Icons.stacked_bar_chart_rounded, 'Competitor Analysis', 'Analyze competitors for my e-commerce store.', 'competitorResearch'),
      (Icons.description_outlined, 'Business Plan Generator', 'Generate a business plan for my e-commerce store.', 'marketingStrategy'),
      (Icons.map_outlined, 'E-commerce Roadmap', 'Create a launch roadmap for my store.', 'competitorResearch'),
      (Icons.rocket_launch_outlined, 'Store Launch Assistant', 'Help me launch my e-commerce store.', null),
      (Icons.trending_up_rounded, 'Growth Coach', 'Act as my growth coach and help me scale my store.', null),
      (Icons.memory_rounded, 'Business Memory', 'What do you remember about my store and business goals?', null),
    ];

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> features = {
          'chat': true,
          'competitorResearch': true,
          'seoOptimizations': true,
          'trendAnalysis': true,
          'marketingStrategy': true,
          'contentGenerationSuite': true,
          'customKnowledgeBase': true,
          'apiAccess': true,
          'whiteLabel': true,
        };

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          final sub = data?['subscription'] as Map<String, dynamic>?;
          if (sub != null && sub['features'] != null) {
            features = Map<String, dynamic>.from(sub['features']);
          } else {
            // Default free plan fallback
            features = {
              'chat': true,
              'competitorResearch': false,
              'seoOptimizations': false,
              'trendAnalysis': false,
              'marketingStrategy': false,
              'contentGenerationSuite': false,
              'customKnowledgeBase': false,
              'apiAccess': false,
              'whiteLabel': false,
            };
          }
        }

        return Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 4),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: actionDefinitions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final def = actionDefinitions[index];
              final featureGate = def.$4;
              final isLocked = featureGate != null && features[featureGate] != true;

              return _QuickActionChip(
                icon: def.$1,
                label: def.$2,
                prompt: def.$3,
                isLocked: isLocked,
              );
            },
          ),
        );
      },
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String prompt;
  final bool isLocked;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.prompt,
    required this.isLocked,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> {
  bool _hovered = false;

  void _showUpgradeDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.lightCyan.withValues(alpha: 0.3), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.orangeAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$featureName Locked',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'This premium feature is not enabled on your current plan. Upgrade your subscription to unlock it instantly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlanScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.isLocked) {
            _showUpgradeDialog(context, widget.label);
            return;
          }
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
            color: _hovered
                ? (widget.isLocked
                    ? Colors.orangeAccent.withValues(alpha: 0.1)
                    : AppColors.lightCyan.withValues(alpha: 0.1))
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? (widget.isLocked
                      ? Colors.orangeAccent.withValues(alpha: 0.4)
                      : AppColors.lightCyan.withValues(alpha: 0.4))
                  : AppColors.borderDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isLocked ? Icons.lock_outline_rounded : widget.icon,
                size: 16,
                color: widget.isLocked
                    ? Colors.orangeAccent
                    : (_hovered ? AppColors.lightCyan : Colors.white70),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isLocked
                      ? Colors.orangeAccent
                      : (_hovered ? AppColors.lightCyan : Colors.white70),
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
