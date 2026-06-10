import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_theme.dart';
import '../widgets/chat/chat_header.dart';
import '../utils/network_config.dart';
import '../utils/app_toast.dart';
import 'workspace_detail_screens.dart';
import 'app_settings_screens.dart';
import '../widgets/layout/responsive_layout.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  void _showUpgradeDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.lightCyan.withOpacity(0.3), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
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
              'This premium capability is not enabled on your current plan. Upgrade your subscription to unlock it instantly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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

  void _showStoresSheet(
    BuildContext outerContext,
    String uid,
    List<Map<String, dynamic>> stores,
    Map<String, dynamic> limits,
  ) {
    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (statefulContext, setSheetState) {
            final nameController = TextEditingController();
            final urlController = TextEditingController();
            final maxStoreCount = limits['maxStoreCount'] as int? ?? 1;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(statefulContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: AppColors.lightCyan, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Connected Stores',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Manage your connected e-commerce stores. Limit: ${stores.length} of $maxStoreCount store(s) connected.',
                    style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (stores.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Text('No stores connected.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: stores.length,
                        itemBuilder: (listContext, idx) {
                          final st = stores[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, color: AppColors.lightCyan, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        st['name'] ?? 'Store',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      if (st['url'] != null)
                                        Text(
                                          st['url'],
                                          style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .collection('workspace')
                                          .doc(st['id'])
                                          .delete();
                                      if (!outerContext.mounted) return;
                                      AppToast.show(outerContext, 'Store connection removed.');
                                      Navigator.pop(sheetContext);
                                    } catch (e) {
                                      if (!outerContext.mounted) return;
                                      AppToast.show(outerContext, 'Failed to remove store.', isError: true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (stores.length >= maxStoreCount) {
                        Navigator.pop(sheetContext);
                        _showUpgradeDialog(outerContext, 'Connected Stores');
                        return;
                      }

                      showDialog(
                        context: statefulContext,
                        builder: (dialogContext) {
                          return AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text('Connect New Store', style: TextStyle(color: Colors.white)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Store Name',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightCyan)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: urlController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Store URL (e.g. shopify.com)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightCyan)),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final url = urlController.text.trim();
                                  if (name.isEmpty || url.isEmpty) {
                                    AppToast.show(dialogContext, 'Please fill in all fields', isError: true);
                                    return;
                                  }

                                  Navigator.pop(dialogContext); // close dialog
                                  Navigator.pop(sheetContext); // close sheet

                                  try {
                                    final headers = await NetworkConfig.getHeaders();
                                    final response = await http.post(
                                      Uri.parse('${NetworkConfig.baseUrl}/workspace'),
                                      headers: headers,
                                      body: jsonEncode({
                                        'type': 'store',
                                        'name': name,
                                        'url': url,
                                      }),
                                    );

                                    if (!outerContext.mounted) return;
                                    final resBody = jsonDecode(response.body);
                                    if (response.statusCode == 201 && resBody['success'] == true) {
                                      AppToast.show(outerContext, 'Store connected successfully!');
                                    } else {
                                      final errorMsg = resBody['error'] ?? 'Failed to connect store';
                                      AppToast.show(outerContext, errorMsg, isError: true);
                                    }
                                  } catch (e) {
                                    if (!outerContext.mounted) return;
                                    AppToast.show(outerContext, 'Connection error: $e', isError: true);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightCyan, foregroundColor: Colors.black),
                                child: const Text('Connect'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stores.length >= maxStoreCount ? Colors.grey : AppColors.lightCyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (stores.length >= maxStoreCount) ...[
                          const Icon(Icons.lock_rounded, size: 16),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          stores.length >= maxStoreCount ? 'Limit Reached (Upgrade Now)' : 'Connect New Store',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDocumentsSheet(
    BuildContext outerContext,
    String uid,
    List<Map<String, dynamic>> documents,
    Map<String, dynamic> limits,
    bool isKbLocked,
  ) {
    if (isKbLocked) {
      _showUpgradeDialog(outerContext, 'Custom Knowledge Base');
      return;
    }

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (statefulContext, setSheetState) {
            final nameController = TextEditingController();
            final sizeController = TextEditingController();
            final maxDocumentUploads = limits['maxDocumentUploads'] as int? ?? 3;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(statefulContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_shared_rounded, color: AppColors.lightCyan, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Knowledge Base Documents',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload your store context documents. Limit: ${documents.length} of $maxDocumentUploads documents uploaded.',
                    style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (documents.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Text('No documents uploaded.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: documents.length,
                        itemBuilder: (listContext, idx) {
                          final doc = documents[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description_rounded, color: AppColors.lightCyan, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['name'] ?? 'Document',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      if (doc['sizeMb'] != null)
                                        Text(
                                          '${doc['sizeMb']} MB',
                                          style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .collection('workspace')
                                          .doc(doc['id'])
                                          .delete();
                                      if (!outerContext.mounted) return;
                                      AppToast.show(outerContext, 'Document removed.');
                                      Navigator.pop(sheetContext);
                                    } catch (e) {
                                      if (!outerContext.mounted) return;
                                      AppToast.show(outerContext, 'Failed to remove document.', isError: true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (documents.length >= maxDocumentUploads) {
                        Navigator.pop(sheetContext);
                        _showUpgradeDialog(outerContext, 'Knowledge Base');
                        return;
                      }

                      showDialog(
                        context: statefulContext,
                        builder: (dialogContext) {
                          return AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text('Upload Document', style: TextStyle(color: Colors.white)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Document Name (e.g. sales_q4.pdf)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightCyan)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: sizeController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'File Size (MB)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightCyan)),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final sizeStr = sizeController.text.trim();
                                  final sizeVal = double.tryParse(sizeStr) ?? 0.0;
                                  if (name.isEmpty || sizeStr.isEmpty) {
                                    AppToast.show(dialogContext, 'Please fill in all fields', isError: true);
                                    return;
                                  }

                                  Navigator.pop(dialogContext); // close dialog
                                  Navigator.pop(sheetContext); // close sheet

                                  try {
                                    final headers = await NetworkConfig.getHeaders();
                                    final response = await http.post(
                                      Uri.parse('${NetworkConfig.baseUrl}/workspace'),
                                      headers: headers,
                                      body: jsonEncode({
                                        'type': 'document',
                                        'name': name,
                                        'sizeMb': sizeVal,
                                      }),
                                    );

                                    if (!outerContext.mounted) return;
                                    final resBody = jsonDecode(response.body);
                                    if (response.statusCode == 201 && resBody['success'] == true) {
                                      AppToast.show(outerContext, 'Document uploaded successfully!');
                                    } else {
                                      final errorMsg = resBody['error'] ?? 'Upload failed';
                                      AppToast.show(outerContext, errorMsg, isError: true);
                                    }
                                  } catch (e) {
                                    if (!outerContext.mounted) return;
                                    AppToast.show(outerContext, 'Upload error: $e', isError: true);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightCyan, foregroundColor: Colors.black),
                                child: const Text('Upload'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: documents.length >= maxDocumentUploads ? Colors.grey : AppColors.lightCyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (documents.length >= maxDocumentUploads) ...[
                          const Icon(Icons.lock_rounded, size: 16),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          documents.length >= maxDocumentUploads ? 'Limit Reached' : 'Upload Document',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Text('Not authenticated', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? {};
        final sub = userData['subscription'] as Map<String, dynamic>? ?? {};
        final limits = sub['limits'] as Map<String, dynamic>? ?? {
          'maxStoreCount': 1,
          'maxDocumentUploads': 3,
          'maxUploadSizeMb': 5
        };
        final features = sub['features'] as Map<String, dynamic>? ?? {
          'customKnowledgeBase': false
        };
        final isKbLocked = features['customKnowledgeBase'] != true;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('workspace')
              .snapshots(),
          builder: (context, workspaceSnapshot) {
            final docs = workspaceSnapshot.data?.docs.map((d) => d.data()).toList() ?? [];
            final stores = docs.where((d) => d['type'] == 'store').toList();
            final documents = docs.where((d) => d['type'] == 'document').toList();

            return Scaffold(
              backgroundColor: AppColors.bgDark,
              body: SafeArea(
                child: Column(
                  children: [
                    ChatHeader(
                      isWide: isWide,
                      leading: const SizedBox(width: 48),
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
                              _buildFolderCard(
                                context,
                                title: 'Connected Stores',
                                subtitle: '${stores.length} / ${limits['maxStoreCount']} Connected',
                                icon: Icons.storefront_rounded,
                                onTap: () => _showStoresSheet(context, uid, stores, limits),
                              ),
                              _buildFolderCard(
                                context,
                                title: 'Knowledge Base',
                                subtitle: isKbLocked
                                    ? 'Locked (Enterprise)'
                                    : '${documents.length} / ${limits['maxDocumentUploads']} Docs',
                                icon: Icons.folder_shared_rounded,
                                isLocked: isKbLocked,
                                onTap: () => _showDocumentsSheet(context, uid, documents, limits, isKbLocked),
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
          },
        );
      },
    );
  }

  Widget _buildFolderCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked ? Colors.orangeAccent.withOpacity(0.3) : AppColors.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.orangeAccent.withOpacity(0.1)
                        : AppColors.lightCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : icon,
                    color: isLocked ? Colors.orangeAccent : AppColors.lightCyan,
                    size: 24,
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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
              style: TextStyle(
                color: isLocked ? Colors.orangeAccent.withOpacity(0.7) : AppColors.textGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
