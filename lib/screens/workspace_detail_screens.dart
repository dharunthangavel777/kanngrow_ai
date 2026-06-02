import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';
import '../widgets/chat/chat_header.dart';
import '../../utils/network_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. SAVED PRODUCTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WorkspaceSavedProductsScreen extends StatefulWidget {
  const WorkspaceSavedProductsScreen({super.key});

  @override
  State<WorkspaceSavedProductsScreen> createState() => _WorkspaceSavedProductsScreenState();
}

class _WorkspaceSavedProductsScreenState extends State<WorkspaceSavedProductsScreen> {
  List<dynamic> _ideas = [];
  bool _loading = true;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchSavedIdeas();
  }

  Future<void> _fetchSavedIdeas() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/ecommerce/ideas/saved'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _ideas = body['data']['ideas'] ?? [];
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load ideas');
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading saved products: $e');
    }
  }

  Future<void> _deleteIdea(String ideaId, String name) async {
    try {
      final response = await http.delete(
        Uri.parse('${NetworkConfig.baseUrl}/ecommerce/ideas/saved/$ideaId'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _ideas.removeWhere((idea) => idea['id'] == ideaId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$name" from workspace'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to delete idea');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting product idea'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

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
              title: const Text(
                'Saved Products',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              trailing: HeaderBtn(
                onTap: _fetchSavedIdeas,
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                    )
                  : _ideas.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _ideas.length,
                          itemBuilder: (context, idx) {
                            final idea = Map<String, dynamic>.from(_ideas[idx]);
                            return _buildIdeaItem(idea, idx);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No Saved Products',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask the Kangrow AI chat to generate and save product ideas.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaItem(Map<String, dynamic> idea, int idx) {
    final isExpanded = _expandedIndices.contains(idx);
    final name = idea['name'] ?? 'Product Idea';
    final niche = idea['niche'] ?? 'Category';
    final margin = idea['margin'] ?? '80%';
    final score = idea['viabilityScore'] ?? idea['demandScore'] ?? 80;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(niche, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentSuccess.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(score / 10).toStringAsFixed(1)}',
                    style: const TextStyle(color: AppColors.accentSuccess, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                  onPressed: () => _deleteIdea(idea['id'], name),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedIndices.remove(idx);
                } else {
                  _expandedIndices.add(idx);
                }
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.borderDark),
                  const SizedBox(height: 10),
                  _DetailRow('💰 Margin Potential', margin),
                  _DetailRow('⚡ Sourcing Platform', idea['sourcingPlatform'] ?? idea['sourcing'] ?? 'Alibaba'),
                  _DetailRow('🎯 Validation Strategy', idea['validationStrategy'] ?? 'Landing page test'),
                  _DetailRow('📣 Unique Angle', idea['uniqueAngle'] ?? 'Premium packaging & branding'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. ROADMAPS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WorkspaceRoadmapsScreen extends StatefulWidget {
  const WorkspaceRoadmapsScreen({super.key});

  @override
  State<WorkspaceRoadmapsScreen> createState() => _WorkspaceRoadmapsScreenState();
}

class _WorkspaceRoadmapsScreenState extends State<WorkspaceRoadmapsScreen> {
  List<dynamic> _roadmaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoadmaps();
  }

  Future<void> _fetchRoadmaps() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/workspace?type=roadmap'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _roadmaps = body['data']['items'] ?? [];
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load roadmaps');
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error fetching roadmaps: $e');
    }
  }

  Future<void> _deleteRoadmap(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${NetworkConfig.baseUrl}/workspace/$id'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _roadmaps.removeWhere((item) => item['id'] == id);
        });
      }
    } catch (e) {
      debugPrint('Error deleting roadmap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

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
              title: const Text(
                'Active Roadmaps',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              trailing: HeaderBtn(
                onTap: _fetchRoadmaps,
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                    )
                  : _roadmaps.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _roadmaps.length,
                          itemBuilder: (context, idx) {
                            final roadmap = Map<String, dynamic>.from(_roadmaps[idx]);
                            return _buildRoadmapItem(roadmap);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No Active Roadmaps',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask the AI chat to generate a roadmap for your business.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapItem(Map<String, dynamic> item) {
    final roadmapData = item['data'] ?? {};
    final List<dynamic> milestones = roadmapData['milestones'] ?? [];
    final id = item['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚀', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text(
                'Launch Roadmap',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                onPressed: () => _deleteRoadmap(id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...milestones.map((m) {
            final phase = m['phase'] as String? ?? 'Next Phase';
            final List<dynamic> tasks = m['tasks'] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.lightCyan, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phase, style: const TextStyle(color: AppColors.lightCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ...tasks.map((task) => Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Text('• $task', style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. BUSINESS PLANS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WorkspaceBusinessPlansScreen extends StatefulWidget {
  const WorkspaceBusinessPlansScreen({super.key});

  @override
  State<WorkspaceBusinessPlansScreen> createState() => _WorkspaceBusinessPlansScreenState();
}

class _WorkspaceBusinessPlansScreenState extends State<WorkspaceBusinessPlansScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/workspace?type=business_plan'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _plans = body['data']['items'] ?? [];
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load business plans');
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error fetching plans: $e');
    }
  }

  Future<void> _deletePlan(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${NetworkConfig.baseUrl}/workspace/$id'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _plans.removeWhere((item) => item['id'] == id);
        });
      }
    } catch (e) {
      debugPrint('Error deleting plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

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
              title: const Text(
                'Business Plans',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              trailing: HeaderBtn(
                onTap: _fetchPlans,
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                    )
                  : _plans.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _plans.length,
                          itemBuilder: (context, idx) {
                            final plan = Map<String, dynamic>.from(_plans[idx]);
                            return _buildPlanItem(plan);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No Saved Business Plans',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate business plans inside the AI co-founder chat to save drafts here.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final planData = item['data'] ?? {};
    
    // Extract formatted keys or content
    final title = planData['title'] ?? planData['name'] ?? 'E-commerce Business Plan';
    final executiveSummary = planData['executiveSummary'] ?? planData['description'] ?? 'Plan description';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.lightCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                onPressed: () => _deletePlan(id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            executiveSummary,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.45),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Expand view logic in alert/modal
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  content: SingleChildScrollView(
                    child: Text(
                      jsonEncode(planData),
                      style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppColors.lightCyan)),
                    )
                  ],
                ),
              );
            },
            child: const Text(
              'Read Full Plan →',
              style: TextStyle(color: AppColors.lightCyan, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Row Widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: AppColors.textLightGray, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: Colors.white),
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

// ─────────────────────────────────────────────────────────────────────────────
// 4. MARKET INTELLIGENCE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WorkspaceMarketIntelligenceScreen extends StatelessWidget {
  const WorkspaceMarketIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

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
              title: const Text(
                'Market Intelligence',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              trailing: const SizedBox(width: 44),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.travel_explore_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      'No Market Reports',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate deep-dive market intelligence reports\nusing the AI chat to save them here.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
