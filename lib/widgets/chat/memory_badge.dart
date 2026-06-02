import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kangrow_ai/app_theme.dart';
import 'package:kangrow_ai/providers/chat_provider.dart';

class MemoryBadge extends StatelessWidget {
  const MemoryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Container(
          width: double.infinity,
          color: AppColors.cardBg,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.statusOnline,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusOnline.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (provider.memoryTracking)
                    ? '🟢 E-Commerce Memory Active | 1,246 Insights Saved'
                    : '⚪ Memory Tracking Paused',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
