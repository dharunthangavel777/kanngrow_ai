import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../widgets/chat/chat_header.dart';
import '../utils/network_config.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/profile'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _profile = body['data']['profile'];
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading dashboard profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    final storeName = _profile?['storeName'] ?? 'My E-commerce Store';
    final stageRaw = _profile?['stage'] ?? 'Concept';
    final industry = _profile?['industry'] ?? 'General Store';

    // Map stages to nice progress metrics
    String phaseTitle = 'Phase 1: Concept Discovery';
    String phaseDesc = 'You are currently selecting categories and building your business DNA.';
    double progress = 0.25;

    final stageLower = stageRaw.toLowerCase();
    if (stageLower.contains('validation') || stageLower.contains('mvp') || stageLower.contains('concept')) {
      phaseTitle = 'Phase 2: Idea Validation';
      phaseDesc = 'You are testing your products against market demand and sourcing suppliers.';
      progress = 0.45;
    } else if (stageLower.contains('launch') || stageLower.contains('live')) {
      phaseTitle = 'Phase 3: Store Launch';
      phaseDesc = 'Your store is live! You are generating sales and launching ad campaigns.';
      progress = 0.75;
    } else if (stageLower.contains('scale') || stageLower.contains('grow')) {
      phaseTitle = 'Phase 4: Scaling & Growth';
      phaseDesc = 'You are optimizing margins, building brand moats, and growing revenue.';
      progress = 1.0;
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(
              isWide: isWide,
              leading: HeaderBtn(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
              title: Text(
                storeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: HeaderBtn(
                onTap: _fetchProfile,
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      children: [
                        _buildHealthScoreCard(progress),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Current Stage'),
                        const SizedBox(height: 12),
                        _buildCurrentStageCard(phaseTitle, phaseDesc, progress, industry),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Recent Activities & Insights'),
                        const SizedBox(height: 12),
                        _buildActivityFeed(stageRaw),
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHealthScoreCard(double progress) {
    final healthScore = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.bgDark,
                  color: AppColors.lightCyan,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$healthScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Health Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your store foundation is looking great. Validate your product to increase your score.',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStageCard(String phaseTitle, String phaseDesc, double progress, String industry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  industry,
                  style: const TextStyle(
                    color: AppColors.lightCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            phaseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phaseDesc,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bgDark,
            color: AppColors.lightCyan,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue Chat Sourcing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(String stage) {
    final activities = [
      (Icons.lightbulb_outline_rounded, 'Business DNA Initialized', 'Just now', true),
      (Icons.person_outline_rounded, 'Profile Stage Set: $stage', 'Just now', false),
      (Icons.memory_rounded, 'Context Sourced from Onboarding', 'Just now', false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final isLast = entry.key == activities.length - 1;
          final icon = entry.value.$1;
          final title = entry.value.$2;
          final time = entry.value.$3;
          final highlight = entry.value.$4;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: highlight ? AppColors.lightCyan.withOpacity(0.1) : AppColors.bgDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: highlight ? AppColors.lightCyan : AppColors.textGray),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: highlight ? Colors.white : AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGray, size: 18),
                onTap: () => Navigator.pop(context),
              ),
              if (!isLast)
                Divider(height: 1, indent: 64, color: AppColors.borderDark),
            ],
          );
        }).toList(),
      ),
    );
  }
}
