import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';
import '../../utils/network_config.dart';

class NotificationInboxSheet extends StatefulWidget {
  const NotificationInboxSheet({super.key});

  @override
  State<NotificationInboxSheet> createState() => _NotificationInboxSheetState();
}

class _NotificationInboxSheetState extends State<NotificationInboxSheet> {
  bool _markingRead = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>>? get _notificationsStream {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }

  Future<void> _markAllRead() async {
    if (_markingRead) return;
    setState(() => _markingRead = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        await http.patch(
          Uri.parse('${NetworkConfig.baseUrl}/notifications/read-all'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _markOneRead(String uid, String notifId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
    } catch (_) {}
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'plan_upgrade':
        return Icons.rocket_launch_rounded;
      case 'broadcast':
        return Icons.campaign_rounded;
      case 'market_alert':
        return Icons.trending_up_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'plan_upgrade':
        return AppColors.lightCyan;
      case 'broadcast':
        return Colors.amber;
      case 'market_alert':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: AppColors.lightCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _markAllRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: _markingRead
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.lightCyan))
                          : const Text(
                              'Mark all read',
                              style: TextStyle(
                                  color: AppColors.lightCyan, fontSize: 12),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.borderDark),

            // Notifications list
            Expanded(
              child: uid == null
                  ? const Center(
                      child: Text('Sign in to view notifications',
                          style: TextStyle(color: Colors.white54)))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _notificationsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.lightCyan),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return _buildEmpty();
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final notifId = docs[index].id;
                            final type =
                                data['type'] as String? ?? 'general';
                            final title =
                                data['title'] as String? ?? 'Notification';
                            final body = data['body'] as String? ?? '';
                            final isRead =
                                data['isRead'] as bool? ?? false;
                            final createdAt =
                                data['createdAt'] as String?;

                            return GestureDetector(
                              onTap: () {
                                if (!isRead) _markOneRead(uid, notifId);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? AppColors.cardBg
                                      : AppColors.cardBg.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isRead
                                        ? AppColors.borderDark
                                        : _colorForType(type)
                                            .withOpacity(0.4),
                                    width: isRead ? 1 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: _colorForType(type)
                                            .withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _iconForType(type),
                                        size: 18,
                                        color: _colorForType(type),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: isRead
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  margin:
                                                      const EdgeInsets.only(
                                                          left: 6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _colorForType(type),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (body.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: TextStyle(
                                                color: isRead
                                                    ? AppColors.textGray
                                                    : Colors.white70,
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            _timeAgo(createdAt),
                                            style: const TextStyle(
                                              color: AppColors.textGray,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All caught up!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan upgrades, broadcasts, and market alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textGray, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
