import 'package:flutter/material.dart';
import '../../app_theme.dart';

class RoadmapCard extends StatelessWidget {
  final Map<String, dynamic> metadata;
  const RoadmapCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final roadmapData = metadata['roadmap'] ?? {};
    final List<dynamic> rawMilestones = roadmapData['milestones'] ?? [];
    
    final List<_Milestone> milestones = [];
    if (rawMilestones.isNotEmpty) {
      for (int i = 0; i < rawMilestones.length; i++) {
        final m = Map<String, dynamic>.from(rawMilestones[i]);
        final phaseName = m['phase'] as String? ?? 'Phase ${i + 1}';
        final List<dynamic> tasksList = m['tasks'] ?? [];
        final desc = tasksList.join('\n');
        milestones.add(_Milestone(
          phaseName,
          desc,
          i == 0 ? AppColors.lightCyan : (i == 1 ? AppColors.lightCyanHover : AppColors.textGray),
          i == 0,
        ));
      }
    } else {
      milestones.addAll([
        _Milestone('Week 1–2', 'Research & Market Validation\n• Alibaba sourcing & economics', AppColors.lightCyan, true),
        _Milestone('Week 3–4', 'Design MVP & Prototype\n• Store setup & logo branding', AppColors.lightCyanHover, false),
        _Milestone('Week 5–6', 'Build & Launch MVP\n• Paid campaigns & influencer deals', AppColors.textGray, false),
      ]);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightCyan.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text(
                  'Store Roadmap',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${milestones.length} Phases',
                    style: const TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Timeline items
            ...milestones.asMap().entries.map((e) => _MilestoneItem(
                  milestone: e.value,
                  isLast: e.key == milestones.length - 1,
                )),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Open Full Roadmap →',
                style: TextStyle(
                  color: AppColors.lightCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Milestone {
  final String title;
  final String description;
  final Color color;
  final bool active;
  _Milestone(this.title, this.description, this.color, this.active);
}

class _MilestoneItem extends StatelessWidget {
  final _Milestone milestone;
  final bool isLast;

  const _MilestoneItem({required this.milestone, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and connecting line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: milestone.active ? milestone.color : AppColors.borderDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: milestone.color,
                    width: 2,
                  ),
                  boxShadow: milestone.active
                      ? [
                          BoxShadow(
                            color: milestone.color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.borderDark,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      color: milestone.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.description,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
