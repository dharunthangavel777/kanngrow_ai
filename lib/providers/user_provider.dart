import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';

class UserUsage {
  final int dailyRequestCount;
  final String dailyRequestResetAt;
  final int monthlyTokenCount;

  UserUsage({
    required this.dailyRequestCount,
    required this.dailyRequestResetAt,
    required this.monthlyTokenCount,
  });

  factory UserUsage.fromJson(Map<String, dynamic> json) {
    return UserUsage(
      dailyRequestCount: json['dailyRequestCount'] as int? ?? 0,
      dailyRequestResetAt: json['dailyRequestResetAt'] as String? ?? '',
      monthlyTokenCount: json['monthlyTokenCount'] as int? ?? 0,
    );
  }
}

class UserSubscription {
  final String tier;
  final int dailyRequestsLimit;
  final int monthlyTokensLimit;

  UserSubscription({
    required this.tier,
    required this.dailyRequestsLimit,
    required this.monthlyTokensLimit,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'] as Map<String, dynamic>? ?? {};
    return UserSubscription(
      tier: json['tier'] as String? ?? 'free',
      dailyRequestsLimit: limits['dailyRequests'] as int? ?? 5,
      monthlyTokensLimit: limits['monthlyTokens'] as int? ?? 10000,
    );
  }
}

class UserProvider extends ChangeNotifier {
  UserUsage? _usage;
  UserSubscription? _subscription;
  bool _isLoading = false;

  UserUsage? get usage => _usage;
  UserSubscription? get subscription => _subscription;
  bool get isLoading => _isLoading;

  int get remainingChats {
    if (_subscription == null) return 0;
    
    final used = _usage?.dailyRequestCount ?? 0;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final resetAt = _usage?.dailyRequestResetAt ?? '';
    final isNewDay = resetAt.isNotEmpty && resetAt.substring(0, 10) != todayStr;
    
    final finalUsed = isNewDay ? 0 : used;
    final remaining = _subscription!.dailyRequestsLimit - finalUsed;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/users/me'),
        headers: await NetworkConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final user = body['data']['user'] as Map<String, dynamic>;
          
          if (user['usage'] != null) {
            _usage = UserUsage.fromJson(user['usage'] as Map<String, dynamic>);
          }
          if (user['subscription'] != null) {
            _subscription = UserSubscription.fromJson(user['subscription'] as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void incrementLocalUsage() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final currentCount = _usage?.dailyRequestCount ?? 0;
    final currentResetAt = _usage?.dailyRequestResetAt ?? todayStr;
    final currentMonthlyTokenCount = _usage?.monthlyTokenCount ?? 0;

    _usage = UserUsage(
      dailyRequestCount: currentCount + 1,
      dailyRequestResetAt: currentResetAt.isEmpty ? todayStr : currentResetAt,
      monthlyTokenCount: currentMonthlyTokenCount,
    );
    notifyListeners();
  }
}
