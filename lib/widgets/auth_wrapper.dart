import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/setup/dynamic_onboarding_screen.dart';
import '../services/fcm_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Still initializing Firebase Auth (checking token)
    if (auth.isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.lightCyan,
          ),
        ),
      );
    }

    // 2. User is authenticated, check onboarding completeness
    if (auth.user != null) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.bgDark,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.lightCyan,
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            final onboardingComplete = data?['onboardingComplete'] ?? false;

            if (onboardingComplete == true) {
              return SubscriptionListenerWrapper(
                uid: auth.user!.uid,
                child: const ChatScreen(),
              );
            }
          }

          // Return onboarding wizard if not complete
          return const DynamicOnboardingScreen();
        },
      );
    }

    // 3. User is NOT authenticated, show the standard intro flow
    return const OnboardingScreen();
  }
}

class SubscriptionListenerWrapper extends StatefulWidget {
  final Widget child;
  final String uid;
  const SubscriptionListenerWrapper({super.key, required this.child, required this.uid});

  @override
  State<SubscriptionListenerWrapper> createState() => _SubscriptionListenerWrapperState();
}

class _SubscriptionListenerWrapperState extends State<SubscriptionListenerWrapper> {
  String? _previousTier;

  @override
  void initState() {
    super.initState();
    // Initialize FCM without context — completely background/async
    FCMService.instance.initialize();

    // Set the foreground message UI callback — this is the safe way to link UI to the service
    FCMService.instance.onForegroundMessage = (title, body) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFF22D3EE), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (body.isNotEmpty)
                      Text(
                        body,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    };
  }

  @override
  void dispose() {
    // Clear callback to avoid calling into disposed widget context
    FCMService.instance.onForegroundMessage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          final sub = data?['subscription'] as Map<String, dynamic>? ?? {};
          final currentTier = sub['tier'] as String? ?? 'free';
          final isLifetime = sub['isLifetime'] == true;

          // Detect plan change
          if (_previousTier != null && _previousTier != currentTier) {
            final isUpgrade = _isUpgrade(_previousTier!, currentTier);
            if (isUpgrade) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showUpgradePopup(context, currentTier, isLifetime);
              });
            }
          }

          _previousTier = currentTier;
        }

        return widget.child;
      },
    );
  }

  bool _isUpgrade(String oldTier, String newTier) {
    const tiers = ['free', 'standard', 'premium', 'enterprise'];
    final oldIdx = tiers.indexOf(oldTier);
    final newIdx = tiers.indexOf(newTier);
    return newIdx > oldIdx;
  }

  void _showUpgradePopup(BuildContext context, String tier, bool isLifetime) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.lightCyan.withValues(alpha: 0.3), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: AppColors.lightCyan,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Plan Upgraded!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account has been upgraded to the ${tier[0].toUpperCase()}${tier.substring(1)} Plan${isLifetime ? " (Lifetime)" : ""}. New premium features have been unlocked instantly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
