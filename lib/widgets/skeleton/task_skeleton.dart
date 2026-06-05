import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class TaskSkeleton extends StatelessWidget {
  const TaskSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              const SkeletonContainer(
                width: 24,
                height: 24,
                shape: BoxShape.circle,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SkeletonContainer(
                  height: 60,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
