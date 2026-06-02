import 'package:flutter/material.dart';
import '../../app_theme.dart';

class WizardOptionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const WizardOptionCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightCyan.withValues(alpha: 0.1)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.lightCyan
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.lightCyan.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isSelected ? AppColors.lightCyan : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.lightCyan
                          : Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.lightCyan,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: icon != null ? 36 : 0),
                child: Text(
                  description!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
