import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../../screens/profile_screen.dart';
import '../../screens/notifications_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reusable compact header — used by ChatScreen and ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChatHeader extends StatelessWidget {
  final bool isWide;

  /// Override the centred title widget. Defaults to no title.
  final Widget? title;

  /// Override the left button. Defaults to menu (mobile) / empty (desktop).
  final Widget? leading;

  /// Override the right button. Defaults to bell + profile avatar.
  final Widget? trailing;

  const ChatHeader({
    super.key,
    required this.isWide,
    this.title,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left ─────────────────────────────────────────────────
              if (leading != null)
                leading!
              else if (!isWide)
                _HeaderBtn(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 20),
                )
              else
                const SizedBox(width: 44),

              // ── Centre ───────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: title ?? const SizedBox.shrink(),
                ),
              ),

              // ── Right ────────────────────────────────────────────────
              trailing ??
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NotificationBell(),
                      SizedBox(width: 12),
                      _ProfileAvatar(size: 36),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass icon button (public — used by screens passing custom trailing)
// ─────────────────────────────────────────────────────────────────────────────
class HeaderBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const HeaderBtn({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark, width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// Private alias for internal use
class _HeaderBtn extends HeaderBtn {
  const _HeaderBtn({required super.child, required super.onTap});
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile avatar
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final double size;
  const _ProfileAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final email = user?.email;
    final name = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : (email != null && email.isNotEmpty)
            ? email.split('@')[0]
            : (user?.isAnonymous ?? false ? 'Apple User' : 'E-commerce Founder');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: size,
        height: size,
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
                  colors: [AppColors.lightCyan, AppColors.lightCyanHover])
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.lightCyan.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: photoUrl == null || photoUrl.isEmpty
            ? Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Bell — live unread count badge using Firestore subcollection
// Note: AggregateQuery.count().get() is used (not .snapshots()) since
// real-time aggregate streaming requires Firebase >= 5.x + index setup.
// We use a StreamBuilder on the full docs query and count client-side instead.
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        HeaderBtn(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: const Icon(Icons.notifications_none_rounded,
              color: Colors.white, size: 20),
        ),
        if (uid != null)
          Positioned(
            right: 4,
            top: 4,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightCyan,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.cardBg, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      count >= 10 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
