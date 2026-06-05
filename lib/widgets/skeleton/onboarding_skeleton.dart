import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class OnboardingSkeleton extends StatelessWidget {
  const OnboardingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const SkeletonContainer(height: 32, width: 250),
          const SizedBox(height: 16),
          const SkeletonContainer(height: 16, width: 300),
          const SizedBox(height: 8),
          const SkeletonContainer(height: 16, width: 200),
          const SizedBox(height: 60),
          const SkeletonContainer(height: 80, borderRadius: 16),
          const SizedBox(height: 16),
          const SkeletonContainer(height: 80, borderRadius: 16),
          const SizedBox(height: 16),
          const SkeletonContainer(height: 80, borderRadius: 16),
        ],
      ),
    );
  }
}
