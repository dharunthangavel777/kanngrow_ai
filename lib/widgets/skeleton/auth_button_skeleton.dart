import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class AuthButtonSkeleton extends StatelessWidget {
  const AuthButtonSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SkeletonContainer(
        width: 120,
        height: 16,
        borderRadius: 8,
      ),
    );
  }
}
