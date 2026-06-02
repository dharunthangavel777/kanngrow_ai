import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../screens/profile_screen.dart';
import '../../sheets/notifications_sheet.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Reusable compact header — used by ChatScreen and ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChatHeader extends StatelessWidget {
  final bool isWide;

  /// Override the centred title widget. Defaults to "Kangrow AI" brand text.
  final Widget? title;

  /// Override the left button. Defaults to menu (mobile) / empty (desktop).
  final Widget? leading;

  /// Override the right button. Defaults to profile avatar.
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
              trailing ?? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _NotificationBell(),
                  const SizedBox(width: 12),
                  const _ProfileAvatar(size: 36),
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
// Glass icon button
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
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [AppColors.lightCyan, AppColors.lightCyanHover]),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightCyan.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text('D',
              style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Bell
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HeaderBtn(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const NotificationInboxSheet(),
            );
          },
          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.lightCyan,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A2332), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
