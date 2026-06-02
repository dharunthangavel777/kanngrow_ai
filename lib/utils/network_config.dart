import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/token_service.dart';

class NetworkConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  static Future<Map<String, String>> getHeaders([Map<String, String>? extra]) async {
    final token = await TokenService.getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      // Fallback for development if token is null
      headers['Authorization'] = 'Bearer mock-token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }
}
