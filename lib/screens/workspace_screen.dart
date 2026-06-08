import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/chat/chat_header.dart';
import 'workspace_detail_screens.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

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
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              title: const Text(
                'Workspace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const SizedBox(width: 44),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    crossAxisCount: MediaQuery.of(context).size.width >= 1200
                        ? 4
                        : (MediaQuery.of(context).size.width >= 768 ? 3 : 2),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildFolderCard(
                        context,
                        title: 'Saved Products',
                        subtitle: 'View Ideas',
                        icon: Icons.lightbulb_outline_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkspaceSavedProductsScreen()),
                        ),
                      ),
                      _buildFolderCard(
                        context,
                        title: 'Roadmaps & Tasks',
                        subtitle: 'View Active',
                        icon: Icons.map_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkspaceRoadmapsScreen()),
                        ),
                      ),
                      _buildFolderCard(
                        context,
                        title: 'Market Intelligence',
                        subtitle: 'View Reports',
                        icon: Icons.travel_explore_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkspaceMarketIntelligenceScreen()),
                        ),
                      ),
                      _buildFolderCard(
                        context,
                        title: 'Business Plans',
                        subtitle: 'View Drafts',
                        icon: Icons.description_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkspaceBusinessPlansScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.lightCyan, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
