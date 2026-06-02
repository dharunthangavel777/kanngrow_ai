import 'package:flutter/material.dart';
import '../app_theme.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    const Text(
                      'Seller Profile',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textGray, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderDark, height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Avatar + Name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.lightCyan,
                                  AppColors.lightCyanHover
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lightCyan.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text('D',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Dharun',
                              style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('dharun@kangrow.ai',
                              style: TextStyle(
                                  color: AppColors.textGray, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('Seller Info'),
                    const SizedBox(height: 12),
                    _InfoField('Current Store', 'Kangrow AI'),
                    const SizedBox(height: 10),
                    _InfoField('Goals', 'Build AI assistant for sellers'),
                    const SizedBox(height: 24),
                    _SectionTitle('Achievements'),
                    const SizedBox(height: 12),
                    _AchievementItem('🎯', 'First Product Validated',
                        'You validated your first product idea'),
                    const SizedBox(height: 10),
                    _AchievementItem('🚀', 'MVP Builder',
                        'You created 3 MVP plans'),
                    const SizedBox(height: 10),
                    _AchievementItem('🏆', 'Conversation Champion',
                        '47 deep seller conversations'),
                    const SizedBox(height: 24),
                    _SectionTitle('Memory & Insights'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard('💾', '1,246', 'Insights')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard('💬', '47', 'Chats')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard('💡', '23', 'Ideas')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ActionButton(
                      'View Saved Ideas',
                      AppColors.lightCyan,
                      AppColors.cardBg,
                      () {},
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      'Export Data',
                      AppColors.textGray,
                      AppColors.cardBg,
                      () {},
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      'Logout',
                      AppColors.danger,
                      Colors.transparent,
                      () {},
                      hasBorder: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textLightGray,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textLightGray, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  const _AchievementItem(this.emoji, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        color: AppColors.textGray, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCard(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppColors.lightCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textGray, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;
  final bool hasBorder;

  const _ActionButton(
      this.label, this.textColor, this.bgColor, this.onTap,
      {this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder
              ? Border.all(color: AppColors.borderDark)
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
