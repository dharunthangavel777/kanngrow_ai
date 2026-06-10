import 'package:flutter/material.dart';


class AuthButtonSkeleton extends StatelessWidget {
  const AuthButtonSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: Colors.grey, // Neutral color visible on both dark/light buttons
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Signing in...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
