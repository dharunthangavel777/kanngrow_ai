import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bgDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF1A1F2E);
  static const Color surfaceCard = Color(0xFF1C2333);
  static const Color cardBg = Color(0xFF1A2332);

  // Accent
  static const Color lightCyan = Color(0xFF2CC7C6);
  static const Color lightCyanHover = Color(0xFF1FA8A7);

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF8B8B8B);
  static const Color textLightGray = Color(0xFF6B7280);

  // Borders
  static const Color borderDark = Color(0xFF2D3748);

  // Status
  static const Color statusOnline = Color(0xFF10B981);
  static const Color accentSuccess = Color(0xFF10B981);

  // Messages
  static const Color messageUserBg = Color(0xFF2CC7C6);

  // Danger
  static const Color danger = Color(0xFFFF6B6B);
}

class AppTextStyles {
  static TextStyle title(BuildContext context) => const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textWhite,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  static TextStyle bodyBold(BuildContext context) => const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textWhite,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle body(BuildContext context) => const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textWhite,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle caption(BuildContext context) => const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textGray,
        fontSize: 13,
        fontWeight: FontWeight.normal,
      );

  static TextStyle small(BuildContext context) => const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textLightGray,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lightCyan,
      secondary: AppColors.lightCyanHover,
      surface: AppColors.surfaceDark,
      onPrimary: Colors.black,
      onSurface: AppColors.textWhite,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Outfit',
      bodyColor: AppColors.textWhite,
      displayColor: AppColors.textWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.textWhite),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textLightGray, fontSize: 14),
    ),
  );
}
