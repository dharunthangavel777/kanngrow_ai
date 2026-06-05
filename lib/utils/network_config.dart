import '../services/token_service.dart';

class NetworkConfig {
  static String get baseUrl {
    return 'https://kanngrowbackend-production.up.railway.app/api/v1';
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
