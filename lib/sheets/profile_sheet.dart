import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../utils/app_toast.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_wrapper.dart';

class ProfileSheet extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback? onSaved;
  const ProfileSheet({super.key, this.profile, this.onSaved});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _storeNameController = TextEditingController();
  final _goalController = TextEditingController();
  final _industryController = TextEditingController();
  final _audienceController = TextEditingController();
  final _budgetController = TextEditingController();
  final _experienceController = TextEditingController();
  
  bool _saving = false;
  int _chatsCount = 0;
  int _ideasCount = 0;
  int _workspaceCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _storeNameController.text = widget.profile?['storeName'] ?? '';
    _goalController.text = widget.profile?['goal'] ?? '';
    _industryController.text = widget.profile?['industry'] ?? '';
    _audienceController.text = widget.profile?['targetAudience'] ?? '';
    _budgetController.text = widget.profile?['budget'] ?? '';
    _experienceController.text = widget.profile?['experienceLevel'] ?? '';
    _fetchStats();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _goalController.dispose();
    _industryController.dispose();
    _audienceController.dispose();
    _budgetController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      final chatsCountSnap = await firestore.collection('users').doc(uid).collection('chatSessions').count().get();
      final ideasCountSnap = await firestore.collection('users').doc(uid).collection('ideas').count().get();
      final workspaceCountSnap = await firestore.collection('users').doc(uid).collection('workspace').count().get();

      if (mounted) {
        setState(() {
          _chatsCount = chatsCountSnap.count ?? 0;
          _ideasCount = ideasCountSnap.count ?? 0;
          _workspaceCount = workspaceCountSnap.count ?? 0;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats for profile sheet: $e');
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No logged in user found.');

      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set({
        'storeName': _storeNameController.text.trim(),
        'goal': _goalController.text.trim(),
        'industry': _industryController.text.trim(),
        'targetAudience': _audienceController.text.trim(),
        'budget': _budgetController.text.trim(),
        'experienceLevel': _experienceController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      widget.onSaved?.call();
      if (mounted) {
        AppToast.show(context, 'Profile updated successfully!', icon: Icons.check_circle_outline_rounded);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to save profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'anonymous@kangrow.ai';
    final rawName = user?.displayName ?? '';
    final name = rawName.isNotEmpty ? rawName : (user?.isAnonymous ?? false ? 'Apple User' : 'E-commerce Founder');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    const Text(
                      'Seller Profile',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textGray, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderDark, height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Avatar + Name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.lightCyan,
                                  AppColors.lightCyanHover
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lightCyan.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(initial,
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(name,
                              style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(email,
                              style: const TextStyle(
                                  color: AppColors.textGray, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _SectionTitle('Seller Info'),
                    const SizedBox(height: 12),
                    _buildTextField('Current Store', _storeNameController, hint: 'My Store Name'),
                    _buildTextField('Main Goal', _goalController, hint: 'Launch my first online store'),
                    _buildTextField('Industry Niche', _industryController, hint: 'Fashion, tech, services, etc.'),
                    _buildTextField('Target Audience', _audienceController, hint: 'Gen Z, professionals, parents, etc.'),
                    _buildTextField('Starting Budget', _budgetController, hint: '₹10,000 - ₹50,000'),
                    _buildTextField('Experience Level', _experienceController, hint: 'Beginner, Intermediate, Expert'),
                    
                    const SizedBox(height: 24),
                    _SectionTitle('Achievements'),
                    const SizedBox(height: 12),
                    _AchievementItem('🎯', 'First Product Validated',
                        'You validated your first product idea', earned: _workspaceCount > 0),
                    const SizedBox(height: 10),
                    _AchievementItem('🚀', 'MVP Builder',
                        'Generate multiple roadmaps to earn', earned: _workspaceCount > 1),
                    const SizedBox(height: 10),
                    _AchievementItem('🏆', 'Conversation Champion',
                        'Start a chat co-founder conversation to earn', earned: _chatsCount > 0),
                    
                    const SizedBox(height: 24),
                    _SectionTitle('Memory & Insights'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatCard('💾', _loadingStats ? '...' : '$_workspaceCount', 'Insights')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard('💬', _loadingStats ? '...' : '$_chatsCount', 'Chats')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard('💡', _loadingStats ? '...' : '$_ideasCount', 'Ideas')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _ActionButton(
                      _saving ? 'Saving...' : 'Save Changes',
                      Colors.black,
                      AppColors.lightCyan,
                      _saving ? () {} : _saveChanges,
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      'Logout',
                      AppColors.danger,
                      Colors.transparent,
                      () async {
                        Navigator.pop(context); // close sheet
                        await context.read<AuthProvider>().signOut(context);
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthWrapper()),
                          (route) => false,
                        );
                      },
                      hasBorder: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLightGray, fontSize: 11)),
          TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: AppColors.lightCyan,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              hintStyle: TextStyle(color: AppColors.textGray.withOpacity(0.5), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 6, bottom: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textLightGray,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool earned;
  const _AchievementItem(this.emoji, this.title, this.description, {required this.earned});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned ? AppColors.lightCyan.withOpacity(0.2) : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          color: AppColors.textGray, fontSize: 12)),
                ],
              ),
            ),
            if (earned)
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.lightCyan, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCard(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppColors.lightCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textGray, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;
  final bool hasBorder;

  const _ActionButton(
      this.label, this.textColor, this.bgColor, this.onTap,
      {this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder
              ? Border.all(color: AppColors.borderDark)
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
