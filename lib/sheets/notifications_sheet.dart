import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';

class NotificationInboxSheet extends StatelessWidget {
  const NotificationInboxSheet({super.key});

  String _formatTime(String? sentAt) {
    if (sentAt == null) return 'Unknown time';
    try {
      final dt = DateTime.parse(sentAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('tip') || t.contains('growth')) return Icons.lightbulb_outline_rounded;
    if (t.contains('analysis') || t.contains('competitor')) return Icons.bar_chart_rounded;
    if (t.contains('memory') || t.contains('engine')) return Icons.memory_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.notifications_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Content
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'Error loading notifications: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Filter client-side for type == 'broadcast'
                  final broadcastDocs = docs.where((doc) {
                    final data = doc.data();
                    return data['type'] == 'broadcast';
                  }).toList();

                  // Sort client-side descending by sentAt
                  broadcastDocs.sort((a, b) {
                    final aSentAt = a.data()['sentAt'] as String? ?? '';
                    final bSentAt = b.data()['sentAt'] as String? ?? '';
                    return bSentAt.compareTo(aSentAt);
                  });

                  if (broadcastDocs.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shrinkWrap: true,
                    itemCount: broadcastDocs.length,
                    itemBuilder: (context, index) {
                      final doc = broadcastDocs[index];
                      final data = doc.data();
                      final title = data['title'] as String? ?? 'Announcement';
                      final body = data['body'] as String? ?? '';
                      final sentAt = data['sentAt'] as String?;
                      
                      return _NotificationItem(
                        icon: _getIcon(title),
                        title: title,
                        subtitle: body,
                        time: _formatTime(sentAt),
                        isUnread: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnread 
                ? AppColors.lightCyan.withValues(alpha: 0.15)
                : AppColors.cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isUnread ? AppColors.lightCyan : Colors.white54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.lightCyan,
                          shape: BoxShape.circle,
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
