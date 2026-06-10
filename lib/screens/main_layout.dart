import 'package:flutter/material.dart';
import 'package:kangrow_ai/app_theme.dart';
import 'package:kangrow_ai/screens/chat_screen.dart';
import 'package:kangrow_ai/screens/home_dashboard_screen.dart';
import 'package:kangrow_ai/screens/task_manager_screen.dart';
import 'package:kangrow_ai/screens/workspace_screen.dart';
import 'package:kangrow_ai/screens/profile_screen.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/layout/app_navigation_rail.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 1}); // Default to Chat

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeDashboardScreen(),
    const ChatScreen(),
    const WorkspaceScreen(),
    const TaskManagerScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavigate(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.lightCyan,
          unselectedItemColor: AppColors.textGray,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onNavigate,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Workspace'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      tabletBody: Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavigate,
              extended: false,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      desktopBody: Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavigate,
              extended: true,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
