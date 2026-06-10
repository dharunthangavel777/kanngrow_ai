import 'package:flutter/material.dart';
import 'package:kangrow_ai/app_theme.dart';

class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final bool extended;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.surfaceDark,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minExtendedWidth: 200,
      indicatorColor: AppColors.lightCyan.withOpacity(0.2),
      selectedIconTheme: const IconThemeData(color: AppColors.lightCyan),
      unselectedIconTheme: const IconThemeData(color: AppColors.textGray),
      selectedLabelTextStyle: AppTextStyles.small(context).copyWith(color: AppColors.lightCyan, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: AppTextStyles.small(context),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: Text('Chat'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder_rounded),
          label: Text('Workspace'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.check_circle_outline_rounded),
          selectedIcon: Icon(Icons.check_circle_rounded),
          label: Text('Tasks'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Profile'),
        ),
      ],
    );
  }
}
