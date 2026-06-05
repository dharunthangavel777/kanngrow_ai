import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/network_config.dart';
import '../app_theme.dart';
import '../sheets/app_sheets.dart';
import '../sheets/notifications_sheet.dart';
import '../sheets/profile_sheet.dart';
import '../widgets/chat/chat_header.dart';
import '../widgets/auth_wrapper.dart';
import '../widgets/skeleton/profile_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/profile'),
        headers: await NetworkConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _profile = body['data']['profile'];
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double gradientHeight = 120.0;
    const double headerHeight  = 60.0;
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── 1. Full-screen scrollable list ───────────────────────────
          SafeArea(
            child: ListView(
              // top padding clears the floating header + gradient
              padding: const EdgeInsets.fromLTRB(16, headerHeight + 8, 16, 32),
              children: [
                // ── User card (Profile) ──────────────────────────────
                _Card(
                  children: [
                    _loading 
                      ? const ProfileSkeleton()
                      : _UserRow(
                          profile: _profile,
                          onTap: () => _openSheet(context, ProfileSheet(profile: _profile, onSaved: _fetchProfile)),
                        ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Main Menu ────────────────────────────────────────
                _Card(
                  children: [
                    _Row(icon: Icons.workspace_premium_outlined,
                        label: 'Subscription',
                        onTap: () => _openSheet(context, const PlanSheet())),
                    _Divider(),
                    _Row(icon: Icons.security_rounded,
                        label: 'Security',
                        onTap: () => _openSheet(context, const SecuritySheet())),
                    _Divider(),
                    _Row(icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => _openSheet(context, const PreferencesSheet())),
                    _Divider(),
                    _Row(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => _openSheet(context, const NotificationInboxSheet())),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Support & Legal ──────────────────────────────────
                _Card(
                  children: [
                    _Row(
                      icon: Icons.shield_outlined,
                      label: 'Privacy Policy',
                      onTap: () => _openSheet(context, const PrivacyPolicySheet()),
                    ),
                    _Divider(),
                    _Row(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: () => _openSheet(context, const HelpSupportSheet()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Log out ──────────────────────────────────────────
                _Card(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmLogout(context),
                        splashColor: Colors.white.withValues(alpha: 0.04),
                        highlightColor: Colors.white.withValues(alpha: 0.02),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, color: AppColors.danger.withValues(alpha: 0.7), size: 20),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text('Log Out',
                                    style: TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── App Version ──────────────────────────────────────
                Center(
                  child: Text(
                    'Version 1.0.0 (Build 1)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. TOP gradient: bgDark → 95% → transparent ─────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: gradientHeight,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      AppColors.bgDark,                          // solid
                      AppColors.bgDark.withValues(alpha: 0.40),  // 40%
                      Colors.transparent,                        // dissolves
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. ChatHeader floats on top of the gradient ──────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: ChatHeader(
                isWide: isWide,
                leading: HeaderBtn(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
                title: const SizedBox.shrink(),
                trailing: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('You will be returned to the login screen.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5)))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                await context.read<AuthProvider>().signOut(context);
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              },
              child: const Text('Log Out',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rounded card group
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User card row
// ─────────────────────────────────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onTap;
  
  const _UserRow({
    required this.onTap,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Default fallback values if no profile is loaded
    final name = profile?['storeName'] ?? 'User';
    final email = profile?['email'] ?? 'user@kangrow.ai';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.lightCyan, AppColors.lightCyanHover],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightCyan.withValues(alpha: 0.3),
                      blurRadius: 12, spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              ),
              const SizedBox(width: 14),
              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(email,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.25), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Standard row
// ─────────────────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.04),
        highlightColor: Colors.white.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.55), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.22), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divider inside a card
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: 50,
      endIndent: 0,
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}
