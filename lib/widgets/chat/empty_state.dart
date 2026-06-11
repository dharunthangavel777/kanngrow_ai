import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.borderDark, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightCyan.withOpacity(0.15),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 36)),
            ),
          )
              .animate()
              .shimmer(duration: 1000.ms, color: AppColors.lightCyan.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            'Hi, Dharun! 👋',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 400.ms,
                delay: 100.ms,
              ),
          const SizedBox(height: 8),
          Text(
            'Your AI E-Commerce Assistant is ready.\nWhat shall we sell today?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}
