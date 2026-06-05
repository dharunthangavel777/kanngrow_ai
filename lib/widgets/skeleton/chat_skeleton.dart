import 'package:flutter/material.dart';
import 'skeleton_base.dart';

class ChatSkeleton extends StatelessWidget {
  final bool isWide;
  const ChatSkeleton({super.key, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const SkeletonContainer(
                  width: 36,
                  height: 36,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 12),
              ],
              SkeletonContainer(
                width: isUser ? 200.0 + (index * 20 % 80) : 250.0 + (index * 30 % 100),
                height: 60.0 + (index * 15 % 40),
                borderRadius: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}
