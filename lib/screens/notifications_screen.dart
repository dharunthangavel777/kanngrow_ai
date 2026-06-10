import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../utils/network_config.dart';
import '../widgets/chat/chat_header.dart';
import '../widgets/notifications/hot_news_card.dart';

class NotificationsScreen extends StatefulWidget {
  final bool hideBackButton;
  const NotificationsScreen({super.key, this.hideBackButton = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _markingRead = false;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _notificationsStream {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> _markAllRead() async {
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

  Future<void> _markOneRead(String notifId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
    } catch (_) {}
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'plan_upgrade':
        return Icons.rocket_launch_rounded;
      case 'broadcast':
        return Icons.campaign_rounded;
      case 'market_alert':
        return Icons.trending_up_rounded;
      case 'hot_news':
        return Icons.local_fire_department_rounded;
      case 'welcome':
        return Icons.waving_hand_rounded;
      case 'idea_generated':
        return Icons.lightbulb_rounded;
      case 'idea_validated':
        return Icons.verified_rounded;
      case 'business_plan':
        return Icons.description_rounded;
      case 'subscription_warning':
        return Icons.access_time_rounded;
      case 'payment_failed':
        return Icons.error_rounded;
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
      case 'hot_news':
        return const Color(0xFFFF6B00);
      case 'welcome':
        return const Color(0xFFA78BFA);
      case 'idea_generated':
        return const Color(0xFFFBBF24);
      case 'idea_validated':
        return const Color(0xFF34D399);
      case 'business_plan':
        return const Color(0xFF60A5FA);
      case 'subscription_warning':
        return const Color(0xFFF97316);
      case 'payment_failed':
        return const Color(0xFFEF4444);
      default:
        return Colors.white54;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Just now';
    try {
      final date = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}';
    } catch (_) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── 1. Full-screen scrollable list ───────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _notificationsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.lightCyan),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 60 + 8, 16, 32),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final notifId = docs[index].id;
                        final type = data['type'] as String? ?? 'general';
                        final title = data['title'] as String? ?? 'Notification';
                        final body = data['body'] as String? ?? '';
                        final isRead = data['isRead'] as bool? ?? false;
                        final createdAt = data['createdAt'] as String?;

                        if (type == 'hot_news') {
                          final rawItems = data['items'];
                          final items = rawItems is List
                              ? rawItems.whereType<Map<String, dynamic>>().toList()
                              : <Map<String, dynamic>>[];
                          final hook = data['hook'] as String? ?? title;
                          final tier = data['tier'] as String? ?? 'standard';

                          return HotNewsCard(
                            notifId: notifId,
                            hook: hook,
                            items: items,
                            tier: tier,
                            isRead: isRead,
                            timeAgo: _timeAgo(createdAt),
                            onTap: () => _markOneRead(notifId),
                          );
                        }

                        return _buildNotificationCard(
                          notifId: notifId,
                          type: type,
                          title: title,
                          body: body,
                          isRead: isRead,
                          timeAgo: _timeAgo(createdAt),
                          onTapOverride: () {
                            _markOneRead(notifId);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppColors.surfaceDark,
                              constraints: const BoxConstraints(maxWidth: 600),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => Container(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                                ),
                                child: _buildDetailPane(data),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // ── 2. Top Header ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: AppColors.bgDark,
              child: ChatHeader(
                isWide: false,
                leading: widget.hideBackButton
                    ? const SizedBox(width: 44)
                    : HeaderBtn(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                trailing: _markingRead
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lightCyan),
                      )
                    : HeaderBtn(
                        onTap: _markAllRead,
                        child: const Icon(Icons.done_all_rounded, color: AppColors.lightCyan, size: 20),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'general';
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final createdAt = data['createdAt'] as String?;

    final color = _colorForType(type);
    final icon = _iconForType(type);
    final timeDisplay = _timeAgo(createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeDisplay,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 24),
          if (type == 'hot_news') ...[
            _buildHotNewsDetails(data),
          ] else ...[
            Text(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotNewsDetails(Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final tier = data['tier'] as String? ?? 'standard';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.lightCyan.withValues(alpha: 0.35), width: 0.8),
              ),
              child: Text(
                'TIER: ${tier.toUpperCase()}',
                style: const TextStyle(color: AppColors.lightCyan, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${items.length} Daily Insights',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white.withValues(alpha: 0.05)),
            ),
          _buildDetailNewsItem(items[i]),
        ],
      ],
    );
  }

  Widget _buildDetailNewsItem(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? '';
    final body = item['body'] as String? ?? '';
    final tag = item['tag'] as String? ?? 'Market';

    Color tagColor(String tag) {
      switch (tag.toLowerCase()) {
        case 'market':
          return const Color(0xFF60A5FA);
        case 'opportunity':
          return const Color(0xFF34D399);
        case 'risk':
          return const Color(0xFFF87171);
        case 'trend':
          return const Color(0xFFA78BFA);
        case 'tool':
          return const Color(0xFF22D3EE);
        default:
          return Colors.white54;
      }
    }

    final color = tagColor(tag);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
              ),
              child: Text(
                tag.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationCard({
    required String notifId,
    required String type,
    required String title,
    required String body,
    required bool isRead,
    required String timeAgo,
    bool selected = false,
    VoidCallback? onTapOverride,
  }) {
    final color = _colorForType(type);
    final icon = _iconForType(type);

    return GestureDetector(
      onTap: onTapOverride ?? () => _markOneRead(notifId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lightCyan.withValues(alpha: 0.08)
              : (isRead
                  ? AppColors.cardBg
                  : AppColors.cardBg.withValues(alpha: 0.95)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.lightCyan
                : (isRead ? AppColors.borderDark : color.withValues(alpha: 0.4)),
            width: selected || !isRead ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: selected || !isRead ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 2),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        color: selected ? Colors.white70 : (isRead ? AppColors.textGray : Colors.white70),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You\'ll receive updates about plan changes, market opportunities, and platform news here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
