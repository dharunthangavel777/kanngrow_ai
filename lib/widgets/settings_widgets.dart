import 'package:flutter/material.dart';
import '../app_theme.dart';

class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(children: children),
        ),
      );
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: c.withValues(alpha: 0.5), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null && value == null)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.2), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext ctx) => Divider(
        indent: 46,
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.06),
      );
}

class SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              activeTrackColor: AppColors.lightCyan,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}

class SettingsSectionLabel extends StatelessWidget {
  final String text;
  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}
