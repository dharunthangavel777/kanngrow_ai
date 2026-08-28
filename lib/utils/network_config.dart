import 'package:flutter/foundation.dart';
import '../services/token_service.dart';

class NetworkConfig {
  static const String _defaultUrl = kDebugMode
      ? 'http://localhost:3000/api/v1'
      : 'https://kanngrowbackend-production.up.railway.app/api/v1';

  static String get baseUrl {
    return const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: _defaultUrl,
    );
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
