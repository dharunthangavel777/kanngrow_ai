import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // Space for header
          const SkeletonContainer(height: 40, width: 250),
          const SizedBox(height: 8),
          const SkeletonContainer(height: 20, width: 180),
          const SizedBox(height: 40),
          Row(
            children: const [
              Expanded(child: SkeletonContainer(height: 120)),
              SizedBox(width: 16),
              Expanded(child: SkeletonContainer(height: 120)),
              SizedBox(width: 16),
              Expanded(child: SkeletonContainer(height: 120)),
            ],
          ),
          const SizedBox(height: 40),
          const SkeletonContainer(height: 24, width: 150),
          const SizedBox(height: 16),
          const SkeletonContainer(height: 80),
          const SizedBox(height: 12),
          const SkeletonContainer(height: 80),
          const SizedBox(height: 12),
          const SkeletonContainer(height: 80),
        ],
      ),
    );
  }
}
