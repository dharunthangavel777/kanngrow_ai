import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/network_config.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/chat/chat_header.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared responsive screen wrapper
// ─────────────────────────────────────────────────────────────────────────────
class AppSettingsScreenScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool hideBackButton;

  const AppSettingsScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.hideBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(
              isWide: isWide,
              leading: hideBackButton
                  ? const SizedBox(width: 44)
                  : HeaderBtn(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const SizedBox(width: 44),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PLAN / SUBSCRIPTION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PlanScreen extends StatefulWidget {
  final bool hideBackButton;
  const PlanScreen({super.key, this.hideBackButton = false});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _isUpgrading = false;

  Future<void> _initiateCheckout(String tier) async {
    setState(() => _isUpgrading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppToast.show(context, 'User not authenticated', isError: true);
        return;
      }

      final headers = await NetworkConfig.getHeaders();
      final body = jsonEncode({
        'tier': tier,
        'successUrl': 'https://kanngrow.com/billing/success',
        'cancelUrl': 'https://kanngrow.com/billing/cancel',
      });

      final response = await http.post(
        Uri.parse('${NetworkConfig.baseUrl}/billing/checkout'),
        headers: headers,
        body: body,
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200 && resBody['success'] == true) {
        final checkoutUrl = resBody['data']['url'] as String;

        await Clipboard.setData(ClipboardData(text: checkoutUrl));

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Upgrade checkout URL copied!',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              content: Text(
                'The checkout URL has been copied to your clipboard. Please paste it into your browser to complete your subscription securely via Stripe.\n\nURL: $checkoutUrl',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: AppColors.lightCyan)),
                ),
              ],
            ),
          );
        }
      } else {
        final errMsg = resBody['error'] ?? 'Checkout failed';
        if (mounted) {
          AppToast.show(context, errMsg, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to initiate checkout: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpgrading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return AppSettingsScreenScaffold(
        title: 'Plan & Subscription',
        hideBackButton: widget.hideBackButton,
        child: const Center(child: Text('User not signed in.', style: TextStyle(color: Colors.white))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppSettingsScreenScaffold(
            title: 'Plan & Subscription',
            hideBackButton: widget.hideBackButton,
            child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan))),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final sub = data['subscription'] as Map<String, dynamic>? ?? {};
        final currentTier = sub['tier'] as String? ?? 'free';
        final status = sub['status'] as String? ?? 'active';

        return AppSettingsScreenScaffold(
          title: 'Plan & Subscription',
          hideBackButton: widget.hideBackButton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.lightCyan.withOpacity(0.15),
                      AppColors.bgDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightCyan.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, color: AppColors.lightCyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${currentTier[0].toUpperCase()}${currentTier.substring(1)} Plan',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'active' ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: status == 'active' ? Colors.green : Colors.white.withOpacity(0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (currentTier == 'free') ...[
                      _planFeature('10 chats / day limit'),
                      _planFeature('Basic AI Model routing'),
                      _planFeature('Community support access'),
                    ] else if (currentTier == 'standard') ...[
                      _planFeature('100 chats / day limit'),
                      _planFeature('Advanced SEO analysis'),
                      _planFeature('Competitor research tool'),
                      _planFeature('Extended knowledge base access'),
                    ] else if (currentTier == 'premium') ...[
                      _planFeature('500 chats / day limit'),
                      _planFeature('Deep competitor intelligence'),
                      _planFeature('AI content generation suite'),
                      _planFeature('E-commerce strategy roadmaps'),
                    ] else if (currentTier == 'enterprise') ...[
                      _planFeature('5000 chats / day limit'),
                      _planFeature('Custom fine-tuned LLM routing'),
                      _planFeature('Multi-user team management'),
                      _planFeature('API tokens & white-label controls'),
                    ],
                    if (currentTier != 'free') ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Billing Source',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            _formatSourceType(sub['sourceType'] as String?),
                            style: const TextStyle(color: AppColors.lightCyan, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration / Expiry',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            _formatExpiry(sub['isLifetime'] as bool?, sub['currentPeriodEnd'] as String?),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (sub['notes'] != null && (sub['notes'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notes',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                sub['notes'] as String,
                                textAlign: TextAlign.right,
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Available Plans', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              _isUpgrading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                    ))
                  : Column(
                      children: [
                        if (currentTier == 'free')
                          _upgradeOptionCard(
                            tier: 'standard',
                            name: 'Standard Plan',
                            price: '₹1,500 / month',
                            desc: 'Best for small online sellers starting out.',
                            features: ['100 chats / day', 'SEO recommendations', 'Competitor lookup'],
                          ),
                        if (currentTier == 'free' || currentTier == 'standard')
                          _upgradeOptionCard(
                            tier: 'premium',
                            name: 'Premium Plan',
                            price: '₹4,000 / month',
                            desc: 'For growing e-commerce businesses.',
                            features: ['500 chats / day', 'Marketing strategies', 'Content suite'],
                          ),
                        if (currentTier != 'enterprise')
                          _upgradeOptionCard(
                            tier: 'enterprise',
                            name: 'Enterprise Plan',
                            price: 'Custom Pricing',
                            desc: 'Dedicated models and multi-user configurations.',
                            features: ['5000 chats / day', 'Fine-tuned LLM access', 'Team accounts'],
                          ),
                      ],
                    ),

              const SizedBox(height: 24),
              const SettingsSectionLabel('Billing Details'),
              SettingsCard(children: [
                SettingsRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Billing History',
                  onTap: () => AppToast.show(context, 'Loading Stripe invoices…', icon: Icons.receipt_long_outlined),
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment Method',
                  value: sub['stripeSubscriptionId'] != null ? 'Linked Credit Card' : 'None',
                  onTap: () => AppToast.show(context, 'Manage payments securely on Stripe', icon: Icons.credit_card_outlined),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _upgradeOptionCard({
    required String tier,
    required String name,
    required String price,
    required String desc,
    required List<String> features,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: AppColors.lightCyan, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(price, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const Divider(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.lightCyan, size: 14),
                    const SizedBox(width: 8),
                    Text(f, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _initiateCheckout(tier),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightCyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Upgrade Now',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planFeature(String text, {bool isPro = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              isPro ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isPro ? AppColors.lightCyan : Colors.white.withOpacity(0.3),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          ],
        ),
      );

  String _formatSourceType(String? source) {
    if (source == null) return 'Stripe Payment';
    switch (source) {
      case 'payment':
        return 'Stripe Payment';
      case 'admin_assignment':
        return 'Admin Assigned';
      case 'promo':
        return 'Promotional Grant';
      default:
        return 'Special Access';
    }
  }

  String _formatExpiry(bool? isLifetime, String? end) {
    if (isLifetime == true || end == 'lifetime') {
      return 'Lifetime Access';
    }
    if (end == null) {
      return 'None';
    }
    try {
      final expiry = DateTime.parse(end);
      final daysLeft = expiry.difference(DateTime.now()).inDays;
      final dateStr = '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
      if (daysLeft > 0) {
        return '$dateStr ($daysLeft days remaining)';
      } else if (daysLeft == 0) {
        return '$dateStr (Expires today)';
      } else {
        return '$dateStr (Expired)';
      }
    } catch (_) {
      return end.split('T')[0];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SECURITY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SecurityScreen extends StatefulWidget {
  final bool hideBackButton;
  const SecurityScreen({super.key, this.hideBackButton = false});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometrics = true;
  bool _twoFactor = false;
  bool _sessionAlerts = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final security = data['securitySettings'] as Map<String, dynamic>?;
        if (security != null) {
          setState(() {
            _biometrics = security['biometrics'] ?? true;
            _twoFactor = security['twoFactor'] ?? false;
            _sessionAlerts = security['sessionAlerts'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'securitySettings': {
          key: value,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving security setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScreenScaffold(
      title: 'Security',
      hideBackButton: widget.hideBackButton,
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF052E16).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                        ),
                        child: const Icon(Icons.verified_user_outlined,
                            color: Color(0xFF22C55E), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Secured',
                                style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Your account is protected',
                                style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SettingsSectionLabel('Authentication'),
                SettingsCard(children: [
                  SettingsToggle(
                    icon: Icons.fingerprint_rounded,
                    label: 'Biometric Unlock',
                    subtitle: 'Use fingerprint or face ID to unlock',
                    value: _biometrics,
                    onChanged: (v) {
                      setState(() => _biometrics = v);
                      _saveSetting('biometrics', v);
                      AppToast.show(context,
                          v ? 'Biometrics enabled' : 'Biometrics disabled');
                    },
                  ),
                  const SettingsDivider(),
                  SettingsToggle(
                    icon: Icons.security_rounded,
                    label: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    value: _twoFactor,
                    onChanged: (v) {
                      setState(() => _twoFactor = v);
                      _saveSetting('twoFactor', v);
                      AppToast.show(context,
                          v ? '2FA enabled — check your email' : '2FA disabled',
                          icon: v
                              ? Icons.security_rounded
                              : Icons.no_encryption_gmailerrorred_rounded,
                          isWarning: !v);
                    },
                  ),
                ]),

                const SettingsSectionLabel('Activity'),
                SettingsCard(children: [
                  SettingsToggle(
                    icon: Icons.notifications_active_outlined,
                    label: 'Login Alerts',
                    subtitle: 'Get notified of new sign-ins',
                    value: _sessionAlerts,
                    onChanged: (v) {
                      setState(() => _sessionAlerts = v);
                      _saveSetting('sessionAlerts', v);
                      AppToast.show(context,
                          v ? 'Login alerts on' : 'Login alerts off');
                    },
                  ),
                  const SettingsDivider(),
                  SettingsRow(
                    icon: Icons.devices_outlined,
                    label: 'Active Sessions',
                    value: '1 device',
                    onTap: () => AppToast.show(
                        context, 'You have 1 active session',
                        icon: Icons.devices_outlined),
                  ),
                  const SettingsDivider(),
                  SettingsRow(
                    icon: Icons.history_rounded,
                    label: 'Login History',
                    onTap: () => AppToast.show(
                        context, 'Last login: today at 12:10 AM',
                        icon: Icons.history_rounded),
                  ),
                ]),

                const SettingsSectionLabel('Account'),
                SettingsCard(children: [
                  SettingsRow(
                    icon: Icons.lock_reset_rounded,
                    label: 'Change Password',
                    onTap: () => AppToast.show(
                        context, 'Password reset link sent to registered email',
                        icon: Icons.mail_outline_rounded),
                  ),
                  const SettingsDivider(),
                  SettingsRow(
                    icon: Icons.delete_forever_outlined,
                    label: 'Delete Account',
                    color: AppColors.danger,
                    onTap: () => _confirmDelete(context),
                  ),
                ]),
              ],
            ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('This action is permanent and cannot be undone.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppToast.show(context, 'Account deletion requested',
                    icon: Icons.warning_amber_rounded, isError: true);
              },
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. PREFERENCES SCREEN (SETTINGS)
// ─────────────────────────────────────────────────────────────────────────────
class PreferencesScreen extends StatefulWidget {
  final bool hideBackButton;
  const PreferencesScreen({super.key, this.hideBackButton = false});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _language   = 'English';
  String _model      = 'Kangrow 2.0';
  String _respLength = 'Medium';
  bool   _codeBlocks = true;
  bool   _markdown   = true;
  bool   _loading    = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final preferences = data['preferences'] as Map<String, dynamic>?;
        if (preferences != null) {
          setState(() {
            _language = preferences['language'] ?? 'English';
            _model = preferences['model'] ?? 'Kangrow 2.0';
            _respLength = preferences['respLength'] ?? 'Medium';
            _codeBlocks = preferences['codeBlocks'] ?? true;
            _markdown = preferences['markdown'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {
          key: value,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScreenScaffold(
      title: 'Preferences',
      hideBackButton: widget.hideBackButton,
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsSectionLabel('Language & Region'),
                SettingsCard(children: [
                  SettingsRow(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    value: _language,
                    onTap: () => _pick(context, 'Language',
                        ['English', 'Hindi', 'Tamil', 'Spanish'],
                        (v) {
                          setState(() => _language = v);
                          _savePreference('language', v);
                        }),
                  ),
                ]),

                const SettingsSectionLabel('AI Settings'),
                SettingsCard(children: [
                  SettingsRow(
                    icon: Icons.smart_toy_outlined,
                    label: 'AI Model',
                    value: _model,
                    onTap: () => _pick(context, 'AI Model',
                        ['Kangrow 2.0', 'Kangrow Pro', 'GPT-4', 'Claude 3'],
                        (v) {
                          setState(() => _model = v);
                          _savePreference('model', v);
                        }),
                  ),
                  const SettingsDivider(),
                  SettingsRow(
                    icon: Icons.text_fields_rounded,
                    label: 'Response Length',
                    value: _respLength,
                    onTap: () => _pick(context, 'Response Length',
                        ['Concise', 'Medium', 'Detailed', 'Comprehensive'],
                        (v) {
                          setState(() => _respLength = v);
                          _savePreference('respLength', v);
                        }),
                  ),
                ]),

                const SettingsSectionLabel('Display'),
                SettingsCard(children: [
                  SettingsToggle(
                    icon: Icons.code_rounded,
                    label: 'Syntax Highlighting',
                    subtitle: 'Colour code blocks in responses',
                    value: _codeBlocks,
                    onChanged: (v) {
                      setState(() => _codeBlocks = v);
                      _savePreference('codeBlocks', v);
                      AppToast.show(context,
                          v ? 'Syntax highlighting on' : 'Syntax highlighting off');
                    },
                  ),
                  const SettingsDivider(),
                  SettingsToggle(
                    icon: Icons.format_bold_rounded,
                    label: 'Markdown Rendering',
                    subtitle: 'Render bold, italic, and lists',
                    value: _markdown,
                    onChanged: (v) {
                      setState(() => _markdown = v);
                      _savePreference('markdown', v);
                      AppToast.show(context,
                          v ? 'Markdown rendering on' : 'Markdown rendering off');
                    },
                  ),
                ]),
              ],
            ),
    );
  }

  void _pick(BuildContext context, String title, List<String> options,
      ValueChanged<String> onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...options.map((o) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    onPick(o);
                    AppToast.show(context, '$title set to $o');
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PRIVACY POLICY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PrivacyPolicyScreen extends StatelessWidget {
  final bool hideBackButton;
  const PrivacyPolicyScreen({super.key, this.hideBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppSettingsScreenScaffold(
      title: 'Privacy Policy',
      hideBackButton: hideBackButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legalBlock('Last updated: May 2025', isDate: true),
          _legalBlock('1. Information We Collect', isHeading: true),
          _legalBlock(
              'We collect information you provide directly, including your name, email address, and usage data generated while using Kangrow AI.'),
          _legalBlock('2. How We Use Your Information', isHeading: true),
          _legalBlock(
              'Your data is used to personalise your AI experience, improve our models, and provide customer support. We do not sell your personal data to third parties.'),
          _legalBlock('3. AI Memory', isHeading: true),
          _legalBlock(
              'With your consent, Kangrow AI stores context from your conversations to provide personalised, continuous assistance. You can delete this data at any time from your profile settings.'),
          _legalBlock('4. Data Security', isHeading: true),
          _legalBlock(
              'We implement industry-standard security measures including AES-256 encryption at rest and TLS 1.3 in transit to protect your data.'),
          _legalBlock('5. Third-Party Services', isHeading: true),
          _legalBlock(
              'We use trusted third-party services (e.g., Google Sign-In, Apple Sign-In) for authentication. Their privacy policies apply to data processed by those services.'),
          _legalBlock('6. Your Rights', isHeading: true),
          _legalBlock(
              'You have the right to access, correct, or delete your personal data at any time by contacting us at privacy@kangrow.ai.'),
          const SizedBox(height: 8),
          _contactCard('privacy@kangrow.ai'),
        ],
      ),
    );
  }

  Widget _legalBlock(String text, {bool isHeading = false, bool isDate = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: isHeading ? 6 : 14),
        child: Text(text,
            style: TextStyle(
              color: isDate
                  ? Colors.white.withValues(alpha: 0.28)
                  : isHeading
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
              fontSize: isHeading ? 14 : 13,
              fontWeight:
                  isHeading ? FontWeight.w700 : FontWeight.normal,
              height: 1.65,
            )),
      );

  Widget _contactCard(String email) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.lightCyan.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mail_outline_rounded,
                color: AppColors.lightCyan, size: 16),
            const SizedBox(width: 10),
            Text(email,
                style: const TextStyle(
                    color: AppColors.lightCyan, fontSize: 13)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. HELP & SUPPORT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HelpSupportScreen extends StatelessWidget {
  final bool hideBackButton;
  const HelpSupportScreen({super.key, this.hideBackButton = false});

  static const _faqs = [
    (q: 'How does Kangrow AI remember my context?', a: 'When AI Memory is enabled in your profile, Kangrow stores key points from each conversation — your goals, preferences, and decisions — to provide personalised follow-up in future sessions.'),
    (q: 'Can I delete my chat history?', a: 'Yes. Go to Profile → Settings → Data & Privacy → Clear Chat History. This permanently deletes all your conversations.'),
    (q: 'How do I upgrade to Pro?', a: 'Tap "Upgrade to Pro" from your Profile or the sidebar. Pro unlocks unlimited messages, advanced AI models, and persistent memory.'),
    (q: 'Is my data safe?', a: 'All data is encrypted in transit (TLS 1.3) and at rest (AES-256). We never sell your data to third parties.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppSettingsScreenScaffold(
      title: 'Help & Support',
      hideBackButton: hideBackButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact options
          SettingsCard(children: [
            SettingsRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email Support',
              value: 'support@kangrow.ai',
              onTap: () => AppToast.show(context,
                  'Opening email to support@kangrow.ai',
                  icon: Icons.mail_outline_rounded),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Live Chat',
              value: 'Online',
              onTap: () => AppToast.show(context,
                  'Connecting to support…',
                  icon: Icons.chat_bubble_outline_rounded),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.article_outlined,
              label: 'Documentation',
              onTap: () => AppToast.show(context,
                  'Opening docs.kangrow.ai',
                  icon: Icons.open_in_browser_rounded),
            ),
          ]),

          const SettingsSectionLabel('FAQs'),
          ..._faqs.map((faq) => _FaqTile(q: faq.q, a: faq.a)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q, a;
  const _FaqTile({required this.q, required this.a});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.q,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 10),
                Text(widget.a,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                        height: 1.6)),
              ],
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. FEEDBACK SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FeedbackScreen extends StatefulWidget {
  final bool hideBackButton;
  const FeedbackScreen({super.key, this.hideBackButton = false});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  String _category = 'General';
  final _ctrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScreenScaffold(
      title: 'Feedback',
      hideBackButton: widget.hideBackButton,
      child: _submitted ? _successView(context) : _formView(context),
    );
  }

  Widget _formView(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating stars
          Center(
            child: Column(
              children: [
                Text('How are you finding Kangrow?',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: i < _rating
                              ? const Color(0xFFF59E0B)
                              : Colors.white.withValues(alpha: 0.2),
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SettingsSectionLabel('Category'),
          SettingsCard(
            children: ['General', 'Bug Report', 'Feature Request', 'AI Quality']
                .map((cat) => Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _category = cat),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(cat,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14))),
                                  if (_category == cat)
                                    const Icon(Icons.check_rounded,
                                        color: AppColors.lightCyan, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (cat != 'AI Quality')
                          Divider(
                              height: 1,
                              indent: 16,
                              color: Colors.white.withValues(alpha: 0.06)),
                      ],
                    ))
                .toList(),
          ),

          const SettingsSectionLabel('Message'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: AppColors.lightCyan,
              decoration: InputDecoration(
                hintText: 'Tell us what you think…',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              if (_rating == 0 && _ctrl.text.trim().isEmpty) {
                AppToast.show(context,
                    'Please add a rating or message',
                    icon: Icons.warning_amber_rounded,
                    isWarning: true);
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                final uid = user?.uid ?? 'anonymous';
                final email = user?.email ?? 'anonymous';

                await FirebaseFirestore.instance.collection('feedback').add({
                  'uid': uid,
                  'email': email,
                  'rating': _rating,
                  'category': _category,
                  'message': _ctrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                setState(() => _submitted = true);
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(context, 'Failed to submit feedback: $e', isError: true);
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.lightCyan,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Text('Submit Feedback',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ),
        ],
      );

  Widget _successView(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightCyan.withValues(alpha: 0.10),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.lightCyan, size: 34),
              ),
              const SizedBox(height: 20),
              const Text('Thank you!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Your feedback helps us build\na better Kangrow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      height: 1.6)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  if (widget.hideBackButton) {
                    setState(() {
                      _submitted = false;
                      _rating = 0;
                      _ctrl.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Close',
                    style: TextStyle(
                        color: AppColors.lightCyan, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
}
