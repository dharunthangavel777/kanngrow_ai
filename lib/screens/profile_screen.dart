import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../utils/network_config.dart';
import '../app_theme.dart';
import '../sheets/app_sheets.dart';
import '../sheets/notifications_sheet.dart';
import '../sheets/profile_sheet.dart';
import '../widgets/chat/chat_header.dart';
import '../widgets/auth_wrapper.dart';
import '../widgets/skeleton/profile_skeleton.dart';
import 'memory_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _dna;
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
            _dna = body['data']['dna'];
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

                if (!_loading && _dna != null) ...[
                  const SizedBox(height: 24),
                  _DnaCard(dna: _dna),
                ],

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
                        icon: Icons.history_edu_rounded,
                        label: 'Memory Timeline',
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MemoryScreen(),
                              ),
                            )),
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
        backgroundColor: AppColors.surfaceDark,
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
        color: AppColors.surfaceDark,
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
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final email = user?.email ?? profile?['email'] ?? 'user@kangrow.ai';
    final name = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : (email.isNotEmpty && email.contains('@'))
            ? email.split('@')[0]
            : 'User';
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
                  image: photoUrl != null && photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: photoUrl == null || photoUrl.isEmpty
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.lightCyan, AppColors.lightCyanHover],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightCyan.withValues(alpha: 0.3),
                      blurRadius: 12, spreadRadius: 1,
                    ),
                  ],
                ),
                child: photoUrl == null || photoUrl.isEmpty
                    ? Center(
                        child: Text(initial,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      )
                    : null,
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

class _DnaCard extends StatelessWidget {
  final Map<String, dynamic>? dna;

  const _DnaCard({this.dna});

  @override
  Widget build(BuildContext context) {
    if (dna == null) {
      return const SizedBox.shrink();
    }

    final String lang = dna!['language'] ?? 'English';
    final String state = dna!['state'] ?? 'Not set';
    final String city = dna!['city'] ?? '';
    final String location = city.isNotEmpty ? '$city, $state' : state;
    final String stage = dna!['businessStage'] ?? 'Idea';
    final String budget = dna!['budgetLabel'] ?? 'Not set';
    final String risk = dna!['riskTolerance'] ?? 'Medium';
    final String niche = dna!['niche'] ?? 'Exploring';
    final List<dynamic> topics = dna!['preferredTopics'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                color: AppColors.lightCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Co-Founder DNA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "SETUP",
                  style: TextStyle(
                    color: AppColors.lightCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "This is your personalized business profile, established from your onboarding choices. Kangrow uses this to tailor advice specifically to you.",
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _DnaItem(
            icon: Icons.translate_rounded,
            label: "Preferred Language",
            value: lang.toUpperCase(),
          ),
          const Divider(color: Colors.white10, height: 16),
          _DnaItem(
            icon: Icons.location_on_outlined,
            label: "Location Context",
            value: location,
          ),
          const Divider(color: Colors.white10, height: 16),
          _DnaItem(
            icon: Icons.business_center_outlined,
            label: "Business Stage",
            value: stage.toUpperCase(),
          ),
          const Divider(color: Colors.white10, height: 16),
          _DnaItem(
            icon: Icons.payments_outlined,
            label: "Budget Context",
            value: budget,
          ),
          const Divider(color: Colors.white10, height: 16),
          _DnaItem(
            icon: Icons.assessment_outlined,
            label: "Risk Tolerance",
            value: risk.toUpperCase(),
          ),
          const Divider(color: Colors.white10, height: 16),
          _DnaItem(
            icon: Icons.insights_rounded,
            label: "Market Niche",
            value: niche,
          ),
          if (topics.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top Topics Explored",
                  style: TextStyle(
                    color: AppColors.textLightGray,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: topics.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.lightCyan.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.lightCyan.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      t.toString(),
                      style: const TextStyle(
                        color: AppColors.lightCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DnaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DnaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textLightGray,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

