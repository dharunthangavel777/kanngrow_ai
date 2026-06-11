import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';

// Top-level background handler (required by firebase_messaging)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.notification?.title}');
}

class FCMService {
  static final FCMService instance = FCMService._internal();
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  // Optional callback for foreground notifications — set by UI layer
  void Function(String title, String body)? onForegroundMessage;

  /// Call once from main() or early app startup (NO BuildContext needed).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true; // Set early to prevent duplicate calls

    try {
      // Register background handler first (only on native/mobile)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // 1. Request permission (non-blocking — run async after UI is ready)
      _requestPermissionAndRegister();

      // 2. Foreground message listener — calls UI callback if set
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM: Foreground message: ${message.notification?.title}');
        final title = message.notification?.title ?? 'Notification';
        final body = message.notification?.body ?? '';
        onForegroundMessage?.call(title, body);
      });

      // 3. App opened from notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM: App opened from notification tap');
      });

      // 4. Token refresh listener
      _messaging.onTokenRefresh.listen((token) {
        debugPrint('FCM: Token refreshed');
        _uploadToken(token);
      });

    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  /// Requests OS permission and registers FCM token — fire-and-forget.
  void _requestPermissionAndRegister() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM: Permission status: ${settings.authorizationStatus}');

      // Register if already logged in
      if (FirebaseAuth.instance.currentUser != null) {
        await _registerToken();
      }

      // Re-register on future logins
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _registerToken();
        }
      });
    } catch (e) {
      debugPrint('FCM: Permission/register error: $e');
    }
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _uploadToken(token);
      }
    } catch (e) {
      debugPrint('FCM: Failed to get token: $e');
    }
  }

  Future<void> _uploadToken(String token) async {
    try {
      final headers = await NetworkConfig.getHeaders();
      // Skip if no valid auth token
      final auth = headers['Authorization'];
      if (auth == null || auth == 'Bearer mock-token' || auth == 'Bearer null') {
        debugPrint('FCM: Skipping token upload — no auth token yet');
        return;
      }

      final response = await http.post(
        Uri.parse('${NetworkConfig.baseUrl}/profile/fcm-token'),
        headers: headers,
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('FCM: Token registered on backend successfully');
      } else {
        debugPrint('FCM: Backend returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM: Token upload error: $e');
    }
  }
}
