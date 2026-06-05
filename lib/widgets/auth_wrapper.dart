import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/setup/dynamic_onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Still initializing Firebase Auth (checking token)
    if (auth.isInitializing) {
      return const SplashScreen();
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
            return const SplashScreen();
          }
          
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            final onboardingComplete = data?['onboardingComplete'] ?? false;
            
            if (onboardingComplete == true) {
              return const ChatScreen();
            }
          }
          
          // Return onboarding wizard if not complete
          return const DynamicOnboardingScreen();
        },
      );
    }

    // 3. User is NOT authenticated, show the standard intro flow
    return const SplashScreen(next: OnboardingScreen());
  }
}
