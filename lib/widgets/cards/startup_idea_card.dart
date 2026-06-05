import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';
import '../../utils/network_config.dart';

class StartupIdeaCard extends StatefulWidget {
  final Map<String, dynamic> metadata;
  const StartupIdeaCard({super.key, required this.metadata});

  @override
  State<StartupIdeaCard> createState() => _StartupIdeaCardState();
}

class _StartupIdeaCardState extends State<StartupIdeaCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _savedIdeaNames = {};
  bool _saving = false;
  final Map<int, bool> _expandedState = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveIdea(Map<String, dynamic> idea) async {
    setState(() => _saving = true);
    try {
      final response = await http.post(
        Uri.parse('${NetworkConfig.baseUrl}/ecommerce/ideas/save'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({
          'id': idea['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'name': idea['name'] ?? 'Product Idea',
          'niche': idea['niche'] ?? 'E-commerce Niche',
          'targetCustomer': idea['targetCustomer'] ?? idea['targetCost'] ?? 'General Audience',
          'margin': idea['margin'] ?? '75%',
          'competition': idea['competition'] ?? idea['difficulty'] ?? 'Medium',
          'sourcingPlatform': idea['sourcingPlatform'] ?? idea['sourcing'] ?? 'Alibaba',
          'validationStrategy': idea['validationStrategy'] ?? idea['actionPlan'] ?? 'Test demand',
          'uniqueAngle': idea['uniqueAngle'] ?? 'Premium branding',
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _savedIdeaNames.add(idea['name'] as String);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "${idea['name']}" saved to Workspace!'),
            backgroundColor: AppColors.accentSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        throw Exception('Failed to save idea');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error saving idea to backend'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> displayIdeas = widget.metadata['ideas'] ?? [];
    
    if (displayIdeas.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: Colors.white24, size: 32),
            SizedBox(height: 12),
            Text(
              'No product suggestions generated yet.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 380,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: displayIdeas.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final idea = Map<String, dynamic>.from(displayIdeas[index]);
                return _buildCardItem(idea, index);
              },
            ),
          ),
          if (displayIdeas.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayIdeas.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == i
                        ? AppColors.lightCyan
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> idea, int index) {
    final name = idea['name'] ?? 'Product Idea';
    final niche = idea['niche'] ?? 'Niche';
    final margin = idea['margin'] ?? '80%';
    final isSaved = _savedIdeaNames.contains(name);
    
    // Derive a score (from demandScore, viabilityScore, or custom)
    final double rawScore = (idea['viabilityScore'] ?? idea['demandScore'] ?? 85).toDouble();
    final double progressVal = rawScore / 100.0;
    final scoreText = (rawScore / 10.0).toStringAsFixed(1);
    
    final isExpanded = _expandedState[index] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text(
                  'Product Idea',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentSuccess.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$scoreText/10',
                    style: const TextStyle(
                      color: AppColors.accentSuccess,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Idea Name
            Text(
              name,
              style: const TextStyle(
                color: AppColors.lightCyan,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Niche & Subtitle
            Text(
              niche,
              style: const TextStyle(
                color: AppColors.textLightGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Unique angle or description
            Text(
              idea['uniqueAngle'] ?? idea['actionPlan'] ?? 'Unique product idea for your e-commerce startup.',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Score indicator
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressVal,
                backgroundColor: AppColors.borderDark,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentSuccess),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Market Viability', style: TextStyle(color: AppColors.textLightGray, fontSize: 10)),
                Text('${(rawScore).toInt()}%',
                    style: const TextStyle(color: AppColors.accentSuccess, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            
            // Expandable details
            if (isExpanded) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.borderDark, height: 1),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _DetailItem('💰', 'Margin Potential', margin),
                    _DetailItem('🎯', 'Sourcing Platform', idea['sourcingPlatform'] ?? idea['sourcing'] ?? 'Alibaba'),
                    _DetailItem('⚡', 'Validation Strategy', idea['validationStrategy'] ?? 'Ad testing'),
                  ],
                ),
              ),
            ] else
              const Spacer(),
              
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedState[index] = !isExpanded;
                    });
                  },
                  child: Text(
                    isExpanded ? 'Collapse ↑' : 'Explore Details →',
                    style: const TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: (_saving || isSaved) ? null : () => _saveIdea(idea),
                  child: Text(
                    isSaved ? 'Saved ✓' : 'Save Idea',
                    style: TextStyle(
                      color: isSaved
                          ? AppColors.accentSuccess
                          : (_saving ? AppColors.textGray : AppColors.textWhite),
                      fontSize: 13,
                      fontWeight: isSaved ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _DetailItem(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textLightGray, fontSize: 10)),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
