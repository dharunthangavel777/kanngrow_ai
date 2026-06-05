import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'skeleton_base.dart';

class AppStartupSkeleton extends StatelessWidget {
  const AppStartupSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const SkeletonContainer(
            height: 4,
            width: 150,
            borderRadius: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Initializing Kangrow AI Engine...',
            style: TextStyle(
              color: AppColors.textGray.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
