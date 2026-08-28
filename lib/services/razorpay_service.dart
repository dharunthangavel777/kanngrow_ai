import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/network_config.dart';
import '../utils/app_toast.dart';
import '../providers/user_provider.dart';
import '../app_theme.dart';

class RazorpayService {
  late Razorpay _razorpay;
  bool _isInitialized = false;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    _isInitialized = true;
  }

  void openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String planName,
    required String description,
    required String userEmail,
    required String userName,
    String? userPhone,
  }) {
    if (!_isInitialized) {
      debugPrint('RazorpayService is not initialized!');
      return;
    }

    final options = {
      'key': keyId.isNotEmpty ? keyId : 'rzp_test_TV4mdDAUFnXMlA',
      'amount': amountPaise,
      'name': 'Kangrow AI',
      'description': '$planName Subscription (Test Mode)',
      'order_id': orderId.startsWith('order_test_') ? null : orderId, // Only pass valid Razorpay order ID
      'timeout': 300,
      'prefill': {
        'contact': userPhone ?? '9876543210',
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#06B6D4', // AppColors.lightCyan hex
        'backdrop_color': '#0A0A0A',
      },
      'modal': {
        'confirm_close': true,
        'animation': true,
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }

  /// Complete Checkout Flow: Fetch Order from Backend -> Open Razorpay -> Verify -> Activate
  static Future<void> startSubscriptionCheckout({
    required BuildContext context,
    required String tier,
    required String billingCycle,
    required Function(bool isSuccess) onComplete,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppToast.show(context, 'Please sign in to upgrade your plan.', isError: true);
      onComplete(false);
      return;
    }

    try {
      // 1. Create order on backend
      final headers = await NetworkConfig.getHeaders();
      final body = jsonEncode({
        'tier': tier,
        'billingCycle': billingCycle,
      });

      final response = await http.post(
        Uri.parse('${NetworkConfig.baseUrl}/billing/razorpay/create-order'),
        headers: headers,
        body: body,
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode != 200 || resData['success'] != true) {
        final err = resData['error'] ?? 'Failed to initialize order';
        if (context.mounted) {
          AppToast.show(context, err, isError: true);
        }
        onComplete(false);
        return;
      }

      final orderData = resData['data'] as Map<String, dynamic>;
      final orderId = orderData['orderId'] as String;
      final keyId = orderData['keyId'] as String? ?? '';
      final amountPaise = (orderData['amount'] as num).toInt();
      final planName = orderData['planName'] as String? ?? '${tier.toUpperCase()} Plan';

      // 2. Setup Razorpay Controller
      final service = RazorpayService();

      service.initialize(
        onSuccess: (PaymentSuccessResponse paymentRes) async {
          service.dispose();
          if (!context.mounted) return;

          // 3. Verify Payment with Backend
          try {
            AppToast.show(context, 'Verifying payment with security gateway…');

            final verifyRes = await http.post(
              Uri.parse('${NetworkConfig.baseUrl}/billing/razorpay/verify-payment'),
              headers: await NetworkConfig.getHeaders(),
              body: jsonEncode({
                'orderId': paymentRes.orderId ?? orderId,
                'paymentId': paymentRes.paymentId ?? 'pay_test_${DateTime.now().millisecondsSinceEpoch}',
                'signature': paymentRes.signature ?? 'sig_test_verified',
                'tier': tier,
                'billingCycle': billingCycle,
              }),
            );

            final verifyData = jsonDecode(verifyRes.body);

            if (verifyRes.statusCode == 200 && verifyData['success'] == true) {
              if (context.mounted) {
                // Refresh local user state immediately
                await Provider.of<UserProvider>(context, listen: false).fetchUserData();

                _showSuccessCelebration(context, planName);
                onComplete(true);
              }
            } else {
              final msg = verifyData['error'] ?? 'Verification failed';
              if (context.mounted) {
                AppToast.show(context, msg, isError: true);
                onComplete(false);
              }
            }
          } catch (e) {
            if (context.mounted) {
              AppToast.show(context, 'Verification error: $e', isError: true);
              onComplete(false);
            }
          }
        },
        onError: (PaymentFailureResponse failRes) {
          service.dispose();
          if (context.mounted) {
            final msg = failRes.message ?? 'Payment cancelled or declined';
            AppToast.show(context, 'Payment: $msg', isError: true);
          }
          onComplete(false);
        },
        onExternalWallet: (ExternalWalletResponse walletRes) {
          service.dispose();
          if (context.mounted) {
            AppToast.show(context, 'External wallet selected: ${walletRes.walletName}');
          }
          onComplete(false);
        },
      );

      // 4. Open Razorpay Checkout Sheet
      service.openCheckout(
        keyId: keyId,
        orderId: orderId,
        amountPaise: amountPaise,
        planName: planName,
        description: 'Upgrade to $planName ($billingCycle)',
        userEmail: user.email ?? '',
        userName: user.displayName ?? 'Kangrow AI Member',
        userPhone: user.phoneNumber ?? '9876543210',
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, 'Checkout error: $e', isError: true);
      }
      onComplete(false);
    }
  }

  static void _showSuccessCelebration(BuildContext context, String planName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.lightCyan.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightCyan.withOpacity(0.15),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.lightCyan, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Plan Activated!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 Welcome to the $planName!',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Your high-tier AI generation credits, advanced business intelligence tools, and custom models are now immediately available.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Start Creating', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
