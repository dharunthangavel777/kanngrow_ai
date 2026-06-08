import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../utils/network_config.dart';
import '../widgets/chat/chat_header.dart';

class MemoryScreen extends StatefulWidget {
  final bool hideBackButton;
  const MemoryScreen({super.key, this.hideBackButton = false});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  Map<String, dynamic>? _memory;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMemory();
  }

  Future<void> _fetchMemory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/chat/memory'),
        headers: await NetworkConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _memory = body['data']['memory'];
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load memory');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      debugPrint('Error loading memory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double gradientHeight = 120.0;
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── 1. Full-screen scrollable content ────────────────────────
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchMemory,
              color: AppColors.lightCyan,
              backgroundColor: AppColors.surfaceDark,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.lightCyan))
                  : _error != null
                      ? _buildErrorState()
                      : _buildMemoryContent(),
            ),
          ),

          // ── 2. TOP gradient: bgDark → transparent ───────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: gradientHeight,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      AppColors.bgDark,
                      AppColors.bgDark.withValues(alpha: 0.40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. ChatHeader floats on top ──────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: ChatHeader(
                isWide: isWide,
                leading: widget.hideBackButton
                    ? const SizedBox(width: 44)
                    : HeaderBtn(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                title: const Text(
                  "Memory Timeline",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 32),
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Failed to load memory timeline",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _error ?? 'Unknown error occurred',
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: _fetchMemory,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightCyan,
              foregroundColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryContent() {
    final longTerm = _memory?['longTerm'] as Map<String, dynamic>?;
    final workingList = _memory?['working'] as List<dynamic>? ?? [];

    final userStory = longTerm?['userStory'] as String? ?? 'This is the start of your journey. As you chat with your AI co-founder, it will build a personalized summary here.';
    final keyDecisions = List<String>.from(longTerm?['keyDecisions'] ?? []);
    final currentGoals = List<String>.from(longTerm?['currentGoals'] ?? []);

    const double headerHeight = 60.0; // Retrieve the const locally or make sure it matches the parent

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, headerHeight + 10, 16, 32),
          children: [
            // ── 1. Long-term User Story ──────────────────────────────────
            _SectionHeader(
              icon: Icons.history_edu_rounded,
              title: "My Journey Story",
              subtitle: "AI-summarized narrative of your entrepreneurial path",
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                userStory,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── 2. Key Decisions & Goals ─────────────────────────────────
            if (keyDecisions.isNotEmpty || currentGoals.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.bookmark_added_outlined,
                title: "Decisions & Milestones",
                subtitle: "Strategic choices and targets you have set",
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (keyDecisions.isNotEmpty)
                    Expanded(
                      child: _MiniCard(
                        title: "Decided Ideas",
                        items: keyDecisions,
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.statusOnline,
                      ),
                    ),
                  if (keyDecisions.isNotEmpty && currentGoals.isNotEmpty)
                    const SizedBox(width: 12),
                  if (currentGoals.isNotEmpty)
                    Expanded(
                      child: _MiniCard(
                        title: "Active Goals",
                        items: currentGoals,
                        icon: Icons.flag_outlined,
                        iconColor: AppColors.lightCyan,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
            ],

            // ── 3. Working Memory Timeline ──────────────────────────────
            _SectionHeader(
              icon: Icons.timeline_rounded,
              title: "Working Memory Timeline",
              subtitle: "Raw facts and preferences detected in the last 30 days",
            ),
            const SizedBox(height: 16),
            workingList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No working facts stored yet. Continue talking to seed memory.",
                        style: TextStyle(color: AppColors.textLightGray, fontSize: 13),
                      ),
                    ),
                  )
                : _buildWorkingTimeline(workingList),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingTimeline(List<dynamic> working) {
    return Column(
      children: List.generate(working.length, (index) {
        final factObj = working[index] as Map<String, dynamic>;
        final String factText = factObj['fact'] ?? '';
        final String category = factObj['category'] ?? 'general';
        final int importance = factObj['importance'] ?? 5;

        IconData categoryIcon = Icons.info_outline_rounded;
        Color accentColor = AppColors.lightCyan;
        if (category == 'business_idea') {
          categoryIcon = Icons.lightbulb_outline_rounded;
          accentColor = const Color(0xFFFFD54F);
        } else if (category == 'decision') {
          categoryIcon = Icons.gavel_rounded;
          accentColor = AppColors.statusOnline;
        } else if (category == 'budget') {
          categoryIcon = Icons.payments_outlined;
          accentColor = const Color(0xFF81C784);
        } else if (category == 'location') {
          categoryIcon = Icons.location_on_outlined;
          accentColor = const Color(0xFFE57373);
        } else if (category == 'preference') {
          categoryIcon = Icons.tune_rounded;
          accentColor = const Color(0xFFBA68C8);
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline vertical line & dot
              Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(categoryIcon, size: 14, color: accentColor),
                  ),
                  if (index != working.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Fact Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            // Importance indicator
                            Row(
                              children: List.generate(3, (dotIndex) {
                                final bool active = dotIndex < (importance / 3.3).round();
                                return Container(
                                  width: 4, height: 4,
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: active ? accentColor : Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          factText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.lightCyan, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textLightGray, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  const _MiniCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: iconColor, fontSize: 12)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
