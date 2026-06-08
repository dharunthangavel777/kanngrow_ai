import 'package:flutter/material.dart';
import '../app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Styled system toast
// Usage: AppToast.show(context, 'Saved!');
//        AppToast.show(context, 'Deleted', icon: Icons.delete, isError: true);
// ─────────────────────────────────────────────────────────────────────────────
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    bool isError = false,
    bool isWarning = false,
  }) {
    final color = isError
        ? AppColors.danger
        : isWarning
            ? const Color(0xFFF59E0B)
            : AppColors.lightCyan;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: EdgeInsets.zero,
          duration: const Duration(milliseconds: 2500),
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
