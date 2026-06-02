import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/chat_provider.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    const Text('Settings',
                        style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
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
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _SectionHeader('Preferences'),
                        const SizedBox(height: 10),
                        _ToggleItem(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          value: provider.darkMode,
                          onChanged: provider.toggleDarkMode,
                        ),
                        _ToggleItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          value: provider.notifications,
                          onChanged: provider.toggleNotifications,
                        ),
                        _ToggleItem(
                          icon: Icons.memory_outlined,
                          label: 'Memory Tracking',
                          value: provider.memoryTracking,
                          subtitle: 'Allow AI to remember your preferences',
                          onChanged: provider.toggleMemoryTracking,
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader('Chat Settings'),
                        const SizedBox(height: 10),
                        _SelectItem(
                          icon: Icons.smart_toy_outlined,
                          label: 'AI Model',
                          value: provider.aiModel,
                          options: ['GPT-4', 'GPT-3.5', 'Claude'],
                          onChanged: provider.setAiModel,
                        ),
                        _SelectItem(
                          icon: Icons.text_fields_rounded,
                          label: 'Response Length',
                          value: provider.responseLength,
                          options: ['Short', 'Medium', 'Long', 'Detailed'],
                          onChanged: provider.setResponseLength,
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader('Data & Privacy'),
                        const SizedBox(height: 10),
                        _DangerItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Clear Chat History',
                          color: AppColors.danger,
                          onTap: () => _confirmClear(context),
                        ),
                        _DangerItem(
                          icon: Icons.download_outlined,
                          label: 'Download Your Data',
                          color: AppColors.textGray,
                          onTap: () {},
                        ),
                        _DangerItem(
                          icon: Icons.shield_outlined,
                          label: 'Privacy Policy',
                          color: AppColors.textGray,
                          onTap: () {},
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Chats?',
            style: TextStyle(color: AppColors.textWhite, fontSize: 16)),
        content: const Text(
          'This will permanently delete all your chat history.',
          style: TextStyle(color: AppColors.textGray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textLightGray,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGray, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.textGray, fontSize: 11)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.lightCyan,
            activeTrackColor: AppColors.lightCyan.withOpacity(0.3),
            inactiveTrackColor: AppColors.borderDark,
            inactiveThumbColor: AppColors.textGray,
          ),
        ],
      ),
    );
  }
}

class _SelectItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGray, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          DropdownButton<String>(
            value: value,
            items: options
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          style:
                              const TextStyle(color: AppColors.textWhite, fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
            dropdownColor: AppColors.surfaceDark,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textGray, size: 18),
            style: const TextStyle(color: AppColors.lightCyan, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DangerItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DangerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DangerItem> createState() => _DangerItemState();
}

class _DangerItemState extends State<_DangerItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.08)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: widget.color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
