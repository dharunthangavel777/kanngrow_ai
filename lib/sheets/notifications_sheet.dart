import 'package:flutter/material.dart';
import '../../app_theme.dart';

class NotificationInboxSheet extends StatelessWidget {
  const NotificationInboxSheet({super.key});

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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shrinkWrap: true,
                children: [
                  _NotificationItem(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Daily Growth Tip',
                    subtitle: 'Optimize your ad spend by targeting lookalike audiences on Instagram.',
                    time: 'Just now',
                    isUnread: true,
                  ),
                  _NotificationItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Competitor Analysis Ready',
                    subtitle: 'We found 3 new competitors in your niche. Tap to view the report.',
                    time: '2 hours ago',
                    isUnread: true,
                  ),
                  _NotificationItem(
                    icon: Icons.memory_rounded,
                    title: 'Memory Engine Updated',
                    subtitle: 'Added "Eco-friendly packaging" to your business DNA.',
                    time: 'Yesterday',
                    isUnread: false,
                  ),
                  const SizedBox(height: 24),
                ],
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
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
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
