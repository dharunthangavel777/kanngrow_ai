import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const SkeletonContainer(
            width: 48,
            height: 48,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonContainer(height: 15, width: 120),
                SizedBox(height: 6),
                SkeletonContainer(height: 12, width: 160),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
