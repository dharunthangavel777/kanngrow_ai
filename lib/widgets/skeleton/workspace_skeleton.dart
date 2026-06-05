import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class WorkspaceSkeleton extends StatelessWidget {
  const WorkspaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: SkeletonContainer(
            height: 120,
            borderRadius: 16,
          ),
        );
      },
    );
  }
}
