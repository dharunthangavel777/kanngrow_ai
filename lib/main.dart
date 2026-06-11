import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'widgets/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: const KangrowApp(),
    ),
  );
}

class KangrowApp extends StatelessWidget {
  const KangrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kangrow AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthWrapper(),
    );
  }
}
