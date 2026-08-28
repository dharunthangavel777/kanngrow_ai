import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';
import '../app_theme.dart';
import '../utils/app_toast.dart';
import '../services/razorpay_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared sheet base — all sub-screens inherit this look
// ─────────────────────────────────────────────────────────────────────────────
class _AppSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double initialSize;
  const _AppSheet({
    required this.title,
    required this.child,
    this.initialSize = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.45), size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(children: children),
        ),
      );
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  const _SheetRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: c.withValues(alpha: 0.5), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: c, fontSize: 14, fontWeight: FontWeight.w400)),
              ),
              if (value != null)
                Text(value!,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13)),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null && value == null)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.2), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Divider(
      indent: 46, height: 1, thickness: 1,
      color: Colors.white.withValues(alpha: 0.06));
}

class _SheetToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SheetToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11)),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              activeTrackColor: AppColors.lightCyan,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.28),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PRIVACY POLICY
// ─────────────────────────────────────────────────────────────────────────────
class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});
  @override
  Widget build(BuildContext context) => _AppSheet(
        title: 'Privacy Policy',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legalBlock('Last updated: May 2025',
                isDate: true),
            _legalBlock('1. Information We Collect',
                isHeading: true),
            _legalBlock(
                'We collect information you provide directly, including your name, email address, and usage data generated while using Kangrow AI.'),
            _legalBlock('2. How We Use Your Information',
                isHeading: true),
            _legalBlock(
                'Your data is used to personalise your AI experience, improve our models, and provide customer support. We do not sell your personal data to third parties.'),
            _legalBlock('3. AI Memory',
                isHeading: true),
            _legalBlock(
                'With your consent, Kangrow AI stores context from your conversations to provide personalised, continuous assistance. You can delete this data at any time from your profile settings.'),
            _legalBlock('4. Data Security',
                isHeading: true),
            _legalBlock(
                'We implement industry-standard security measures including AES-256 encryption at rest and TLS 1.3 in transit to protect your data.'),
            _legalBlock('5. Third-Party Services',
                isHeading: true),
            _legalBlock(
                'We use trusted third-party services (e.g., Google Sign-In, Apple Sign-In) for authentication. Their privacy policies apply to data processed by those services.'),
            _legalBlock('6. Your Rights',
                isHeading: true),
            _legalBlock(
                'You have the right to access, correct, or delete your personal data at any time by contacting us at privacy@kangrow.ai.'),
            const SizedBox(height: 8),
            _contactCard('privacy@kangrow.ai'),
          ],
        ),
      );

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
// 2. SECURITY
// ─────────────────────────────────────────────────────────────────────────────
class SecuritySheet extends StatefulWidget {
  const SecuritySheet({super.key});
  @override
  State<SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends State<SecuritySheet> {
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
  Widget build(BuildContext context) => _AppSheet(
        title: 'Security',
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

                  _SectionLabel('Authentication'),
                  _SheetCard(children: [
                    _SheetToggle(
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
                    _SheetDivider(),
                    _SheetToggle(
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

                  _SectionLabel('Activity'),
                  _SheetCard(children: [
                    _SheetToggle(
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
                    _SheetDivider(),
                    _SheetRow(
                      icon: Icons.devices_outlined,
                      label: 'Active Sessions',
                      value: '1 device',
                      onTap: () => AppToast.show(
                          context, 'You have 1 active session',
                          icon: Icons.devices_outlined),
                    ),
                    _SheetDivider(),
                    _SheetRow(
                      icon: Icons.history_rounded,
                      label: 'Login History',
                      onTap: () => AppToast.show(
                          context, 'Last login: today at 12:10 AM',
                          icon: Icons.history_rounded),
                    ),
                  ]),

            _SectionLabel('Account'),
            _SheetCard(children: [
              _SheetRow(
                icon: Icons.lock_reset_rounded,
                label: 'Change Password',
                onTap: () => AppToast.show(
                    context, 'Password reset link sent to dharun@kangrow.ai',
                    icon: Icons.mail_outline_rounded),
              ),
              _SheetDivider(),
              _SheetRow(
                icon: Icons.delete_forever_outlined,
                label: 'Delete Account',
                color: AppColors.danger,
                onTap: () => _confirmDelete(context),
              ),
            ]),
          ],
        ),
      );

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
// 3. NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});
  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _pushAll     = true;
  bool _aiResponses = true;
  bool _updates     = false;
  bool _tips        = true;
  bool _email       = false;

  @override
  Widget build(BuildContext context) => _AppSheet(
        title: 'Notifications',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Push Notifications'),
            _SheetCard(children: [
              _SheetToggle(
                icon: Icons.notifications_outlined,
                label: 'All Notifications',
                subtitle: 'Master toggle for all push alerts',
                value: _pushAll,
                onChanged: (v) {
                  setState(() {
                    _pushAll = v;
                    if (!v) {
                      _aiResponses = false;
                      _updates = false;
                      _tips = false;
                    }
                  });
                  AppToast.show(context,
                      v ? 'Notifications enabled' : 'All notifications muted',
                      icon: v
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      isWarning: !v);
                },
              ),
              _SheetDivider(),
              _SheetToggle(
                icon: Icons.smart_toy_outlined,
                label: 'AI Responses',
                subtitle: 'When Kangrow replies to your messages',
                value: _aiResponses,
                onChanged: (v) {
                  setState(() => _aiResponses = v);
                  AppToast.show(context,
                      v ? 'AI response alerts on' : 'AI response alerts off');
                },
              ),
              _SheetDivider(),
              _SheetToggle(
                icon: Icons.system_update_outlined,
                label: 'Product Updates',
                subtitle: 'New features and improvements',
                value: _updates,
                onChanged: (v) {
                  setState(() => _updates = v);
                  AppToast.show(context,
                      v ? 'Update alerts on' : 'Update alerts off');
                },
              ),
              _SheetDivider(),
              _SheetToggle(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Tips & Insights',
                subtitle: 'Daily seller tips from Kangrow',
                value: _tips,
                onChanged: (v) {
                  setState(() => _tips = v);
                  AppToast.show(context, v ? 'Tips enabled' : 'Tips disabled');
                },
              ),
            ]),

            _SectionLabel('Email'),
            _SheetCard(children: [
              _SheetToggle(
                icon: Icons.mail_outline_rounded,
                label: 'Email Digest',
                subtitle: 'Weekly summary of your activity',
                value: _email,
                onChanged: (v) {
                  setState(() => _email = v);
                  AppToast.show(context,
                      v ? 'Email digest subscribed' : 'Email digest unsubscribed',
                      icon: Icons.mail_outline_rounded);
                },
              ),
            ]),

            _SectionLabel('Quiet Hours'),
            _SheetCard(children: [
              _SheetRow(
                icon: Icons.bedtime_outlined,
                label: 'Quiet Hours',
                value: '10 PM – 8 AM',
                onTap: () => AppToast.show(
                    context, 'Quiet hours: 10:00 PM – 8:00 AM',
                    icon: Icons.bedtime_outlined),
              ),
              _SheetDivider(),
              _SheetRow(
                icon: Icons.language_outlined,
                label: 'Time Zone',
                value: 'IST (UTC+5:30)',
                onTap: () => AppToast.show(
                    context, 'Time zone: India Standard Time',
                    icon: Icons.language_outlined),
              ),
            ]),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PLAN & SUBSCRIPTION
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// 4. PLAN & SUBSCRIPTION (RAZORPAY TEST MODE GATEWAY)
// ─────────────────────────────────────────────────────────────────────────────
class PlanSheet extends StatefulWidget {
  const PlanSheet({super.key});

  @override
  State<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<PlanSheet> {
  bool _isUpgrading = false;
  String _billingCycle = 'monthly'; // 'monthly' | 'annual'

  Future<void> _initiateRazorpayCheckout(String tier) async {
    setState(() => _isUpgrading = true);
    await RazorpayService.startSubscriptionCheckout(
      context: context,
      tier: tier,
      billingCycle: _billingCycle,
      onComplete: (isSuccess) {
        if (mounted) {
          setState(() => _isUpgrading = false);
        }
      },
    );
  }

  void _openBillingHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UserBillingHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _AppSheet(
        title: 'Plan & Subscription',
        child: Center(child: Text('User not signed in.', style: TextStyle(color: Colors.white))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _AppSheet(
            title: 'Plan & Subscription',
            child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan))),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final sub = data['subscription'] as Map<String, dynamic>? ?? {};
        final currentTier = sub['tier'] as String? ?? 'free';
        final status = sub['status'] as String? ?? 'active';

        return _AppSheet(
          title: 'Plan & Subscription',
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
                      _planFeature('10 AI chats / day limit'),
                      _planFeature('GPT-4o-mini & basic model routing'),
                      _planFeature('Community assistance access'),
                    ] else if (currentTier == 'standard') ...[
                      _planFeature('100 AI chats / day limit', isPro: true),
                      _planFeature('Advanced E-Commerce SEO Engine', isPro: true),
                      _planFeature('Deep competitor research tool', isPro: true),
                      _planFeature('GPT-4o fast reasoning model', isPro: true),
                    ] else if (currentTier == 'premium') ...[
                      _planFeature('500 AI chats / day limit', isPro: true),
                      _planFeature('Full AI Content Generation Suite', isPro: true),
                      _planFeature('Predictive Trend Analysis & Intelligence', isPro: true),
                      _planFeature('High-Priority Dedicated LLM Queue', isPro: true),
                    ] else if (currentTier == 'enterprise') ...[
                      _planFeature('5,000 AI chats / day limit', isPro: true),
                      _planFeature('Custom fine-tuned LLM & Team Workspaces', isPro: true),
                      _planFeature('API Tokens & White-label exports', isPro: true),
                      _planFeature('24/7 Dedicated Account Manager', isPro: true),
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
                            'Payment Gateway',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            _formatSourceType(sub['sourceType'] as String? ?? sub['gateway'] as String?),
                            style: const TextStyle(color: AppColors.lightCyan, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Validity / Expiry',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            _formatExpiry(sub['isLifetime'] as bool?, sub['currentPeriodEnd'] as String?),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Billing Cycle Switch (Monthly / Annual)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _billingCycle = 'monthly'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _billingCycle == 'monthly' ? AppColors.surfaceDark : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: _billingCycle == 'monthly' ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
                          ),
                          child: Center(
                            child: Text(
                              'Monthly Billing',
                              style: TextStyle(
                                color: _billingCycle == 'monthly' ? Colors.white : Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: _billingCycle == 'monthly' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _billingCycle = 'annual'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _billingCycle == 'annual' ? AppColors.surfaceDark : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: _billingCycle == 'annual' ? Border.all(color: AppColors.lightCyan.withOpacity(0.3)) : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Annual',
                                  style: TextStyle(
                                    color: _billingCycle == 'annual' ? Colors.white : Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                    fontWeight: _billingCycle == 'annual' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightCyan.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SAVE 17%',
                                    style: TextStyle(color: AppColors.lightCyan, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Available Plans', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              _isUpgrading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                          SizedBox(height: 12),
                          Text('Opening Razorpay Payment Gateway…', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ))
                  : Column(
                      children: [
                        if (currentTier == 'free')
                          _upgradeOptionCard(
                            tier: 'standard',
                            name: 'Standard Plan',
                            price: _billingCycle == 'annual' ? '₹14,990 / year' : '₹1,499 / month',
                            desc: 'Perfect for small sellers scaling their online presence.',
                            features: ['100 chats / day limit', 'SEO intelligence suite', 'Competitor keyword tracking', 'GPT-4o engine'],
                          ),
                        if (currentTier == 'free' || currentTier == 'standard')
                          _upgradeOptionCard(
                            tier: 'premium',
                            name: 'Premium Plan',
                            price: _billingCycle == 'annual' ? '₹39,990 / year' : '₹3,999 / month',
                            desc: 'Full-fledged AI Co-Founder for high-volume stores.',
                            features: ['500 chats / day limit', 'Predictive market trends', 'E-commerce content generator', 'Priority processing'],
                          ),
                        if (currentTier != 'enterprise')
                          _upgradeOptionCard(
                            tier: 'enterprise',
                            name: 'Enterprise Plan',
                            price: _billingCycle == 'annual' ? '₹1,49,990 / year' : '₹14,999 / month',
                            desc: 'Dedicated enterprise models, API tokens & multi-user teams.',
                            features: ['5,000 chats / day limit', 'Custom fine-tuned LLM', 'API token access', 'Dedicated SLA support'],
                          ),
                      ],
                    ),

              const SizedBox(height: 24),
              _SectionLabel('Billing Details'),
              _SheetCard(children: [
                _SheetRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Payment & Invoice History',
                  onTap: _openBillingHistory,
                ),
                _SheetDivider(),
                _SheetRow(
                  icon: Icons.security_rounded,
                  label: 'Payment Gateway',
                  value: 'Razorpay Test Gateway',
                  onTap: () => AppToast.show(context, 'Secured with 256-bit Razorpay Gateway encryption', icon: Icons.lock_outline_rounded),
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
            onTap: () => _initiateRazorpayCheckout(tier),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightCyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Pay with Razorpay (Test Mode)',
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
    if (source == null) return 'Razorpay Test Gateway';
    switch (source) {
      case 'razorpay':
      case 'payment':
        return 'Razorpay Gateway';
      case 'admin_assignment':
        return 'Admin Assigned';
      case 'promo':
        return 'Promotional Grant';
      case 'trial':
        return 'Trial Access';
      case 'referral_reward':
        return 'Referral Reward';
      case 'enterprise_contract':
        return 'Enterprise Contract';
      default:
        return 'Razorpay Gateway';
    }
  }

  String _formatExpiry(bool? isLifetime, String? end) {
    if (isLifetime == true || end == 'lifetime') {
      return 'Lifetime Access';
    }
    if (end == null) {
      return 'Active';
    }
    try {
      final date = DateTime.parse(end);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return end;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. USER BILLING & INVOICE HISTORY SHEET
// ─────────────────────────────────────────────────────────────────────────────
class UserBillingHistorySheet extends StatefulWidget {
  const UserBillingHistorySheet({super.key});

  @override
  State<UserBillingHistorySheet> createState() => _UserBillingHistorySheetState();
}

class _UserBillingHistorySheetState extends State<UserBillingHistorySheet> {
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final headers = await NetworkConfig.getHeaders();
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/billing/transactions/me'),
        headers: headers,
      );

      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200 && resBody['success'] == true) {
        if (mounted) {
          setState(() {
            _transactions = resBody['data']['transactions'] as List<dynamic>? ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = resBody['error'] ?? 'Failed to load transaction history';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AppSheet(
      title: 'Payment & Invoice History',
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchTransactions, child: const Text('Retry')),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text('No transactions yet', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = _transactions[index] as Map<String, dynamic>;
                        final planName = tx['planName'] ?? 'Subscription';
                        final amount = tx['amount'] ?? 0;
                        final status = tx['status'] ?? 'captured';
                        final paymentId = tx['paymentId'] ?? tx['id'] ?? '';
                        final dateStr = tx['createdAt'] as String? ?? '';
                        String formattedDate = dateStr;
                        try {
                          final d = DateTime.parse(dateStr);
                          formattedDate = '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
                        } catch (_) {}

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.12),
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.green, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      planName,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: $paymentId',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹$amount',
                                    style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toString().toUpperCase(),
                                      style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. ACHIEVEMENTS
// ─────────────────────────────────────────────────────────────────────────────
class AchievementsSheet extends StatelessWidget {
  const AchievementsSheet({super.key});

  static const _badges = [
    (emoji: '🚀', label: 'First Launch', desc: 'Started your first chat', earned: true),
    (emoji: '💡', label: 'Idea Machine', desc: 'Generated 10 product ideas', earned: true),
    (emoji: '🎯', label: 'Focused Founder', desc: 'Used Kangrow 7 days in a row', earned: true),
    (emoji: '🧠', label: 'Memory Pro', desc: 'Enabled AI Memory', earned: false),
    (emoji: '⚡', label: 'Speed Builder', desc: 'Completed an MVP plan in 1 session', earned: false),
    (emoji: '🌟', label: 'Power User', desc: 'Sent 100 messages', earned: false),
  ];

  @override
  Widget build(BuildContext context) => _AppSheet(
        title: 'Achievements',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3 of 6 earned',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 6,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.lightCyan),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text('50%',
                    style: TextStyle(
                        color: AppColors.lightCyan,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),

            _SectionLabel('Badges'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: _badges
                  .map((b) => _BadgeCard(
                        emoji: b.emoji,
                        label: b.label,
                        desc: b.desc,
                        earned: b.earned,
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}

class _BadgeCard extends StatelessWidget {
  final String emoji, label, desc;
  final bool earned;
  const _BadgeCard(
      {required this.emoji,
      required this.label,
      required this.desc,
      required this.earned});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned
              ? AppColors.lightCyan.withValues(alpha: 0.07)
              : AppColors.bgDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? AppColors.lightCyan.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(earned ? emoji : '🔒',
                style: TextStyle(
                    fontSize: 22,
                    color: earned ? null : null)),
            const Spacer(),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: earned
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 10)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. SAVED IDEAS
// ─────────────────────────────────────────────────────────────────────────────
class SavedIdeasSheet extends StatelessWidget {
  const SavedIdeasSheet({super.key});

  static const _ideas = [
    (title: 'AI-powered invoice automation', tag: 'SaaS', date: '2 days ago'),
    (title: 'Hyper-local grocery delivery for Tier 2 cities', tag: 'Marketplace', date: '5 days ago'),
    (title: 'Micro-learning platform for founders', tag: 'EdTech', date: '1 week ago'),
    (title: 'B2B carbon credit marketplace', tag: 'Climate', date: '2 weeks ago'),
  ];

  @override
  Widget build(BuildContext context) => _AppSheet(
        title: 'Saved Ideas',
        child: Column(
          children: [
            ..._ideas.map(
              (idea) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightCyan.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(idea.tag,
                              style: const TextStyle(
                                  color: AppColors.lightCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(idea.date,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(idea.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ideaBtn('Explore', Icons.arrow_forward_rounded,
                            () => AppToast.show(context, 'Opening idea…',
                                icon: Icons.arrow_forward_rounded),
                            context),
                        const SizedBox(width: 8),
                        _ideaBtn('Remove', Icons.delete_outline_rounded,
                            () => AppToast.show(context, 'Idea removed',
                                icon: Icons.delete_outline_rounded,
                                isError: true),
                            context,
                            isRed: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _ideaBtn(
      String label, IconData icon, VoidCallback onTap, BuildContext context,
      {bool isRed = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isRed
                ? AppColors.danger.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 13,
                  color: isRed
                      ? AppColors.danger
                      : Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: isRed
                          ? AppColors.danger
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12)),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. PREFERENCES
// ─────────────────────────────────────────────────────────────────────────────
class PreferencesSheet extends StatefulWidget {
  const PreferencesSheet({super.key});
  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
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
  Widget build(BuildContext context) => _AppSheet(
        title: 'Preferences',
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
                  _SectionLabel('Language & Region'),
                  _SheetCard(children: [
                    _SheetRow(
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

                  _SectionLabel('AI Settings'),
                  _SheetCard(children: [
                    _SheetRow(
                      icon: Icons.smart_toy_outlined,
                      label: 'AI Model',
                      value: _model,
                      onTap: () => _pick(context, 'AI Model',
                          ['Kangrow 2.0', 'Kangrow Pro', 'Fast (GPT-4o-mini)', 'GPT-4', 'Claude 3'],
                          (v) {
                            setState(() => _model = v);
                            _savePreference('model', v);
                          }),
                    ),
                    _SheetDivider(),
                    _SheetRow(
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

                  _SectionLabel('Display'),
                  _SheetCard(children: [
                    _SheetToggle(
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
                    _SheetDivider(),
                    _SheetToggle(
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
// 8. HELP & SUPPORT
// ─────────────────────────────────────────────────────────────────────────────
class HelpSupportSheet extends StatelessWidget {
  const HelpSupportSheet({super.key});

  static const _faqs = [
    (q: 'How does Kangrow AI remember my context?', a: 'When AI Memory is enabled in your profile, Kangrow stores key points from each conversation — your goals, preferences, and decisions — to provide personalised follow-up in future sessions.'),
    (q: 'Can I delete my chat history?', a: 'Yes. Go to Profile → Settings → Data & Privacy → Clear Chat History. This permanently deletes all your conversations.'),
    (q: 'How do I upgrade to Pro?', a: 'Tap "Upgrade to Pro" from your Profile or the sidebar. Pro unlocks unlimited messages, advanced AI models, and persistent memory.'),
    (q: 'Is my data safe?', a: 'All data is encrypted in transit (TLS 1.3) and at rest (AES-256). We never sell your data to third parties.'),
  ];

  @override
  Widget build(BuildContext context) => _AppSheet(
        title: 'Help & Support',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact options
            _SheetCard(children: [
              _SheetRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email Support',
                value: 'support@kangrow.ai',
                onTap: () => AppToast.show(context,
                    'Opening email to support@kangrow.ai',
                    icon: Icons.mail_outline_rounded),
              ),
              _SheetDivider(),
              _SheetRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Live Chat',
                value: 'Online',
                onTap: () => AppToast.show(context,
                    'Connecting to support…',
                    icon: Icons.chat_bubble_outline_rounded),
              ),
              _SheetDivider(),
              _SheetRow(
                icon: Icons.article_outlined,
                label: 'Documentation',
                onTap: () => AppToast.show(context,
                    'Opening docs.kangrow.ai',
                    icon: Icons.open_in_browser_rounded),
              ),
            ]),

            _SectionLabel('FAQs'),
            ..._faqs.map((faq) => _FaqTile(q: faq.q, a: faq.a)),
          ],
        ),
      );
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
            color: AppColors.bgDark,
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
// 9. FEEDBACK
// ─────────────────────────────────────────────────────────────────────────────
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});
  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
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
  Widget build(BuildContext context) => _AppSheet(
        title: 'Feedback',
        initialSize: 0.90,
        child: _submitted ? _successView(context) : _formView(context),
      );

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

          _SectionLabel('Category'),
          _SheetCard(
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

          _SectionLabel('Message'),
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
                onTap: () => Navigator.pop(context),
                child: Text('Close',
                    style: TextStyle(
                        color: AppColors.lightCyan, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
}
