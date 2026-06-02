import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app_theme.dart';
import '../../screens/home_dashboard_screen.dart';
import '../../screens/task_manager_screen.dart';
import '../../screens/workspace_screen.dart';

class FloatingActionMenu extends StatefulWidget {
  const FloatingActionMenu({super.key});

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;
  double _left = -1;
  double _top = -1;

  Timer? _hideTimer;
  bool _isHalfHidden = false;
  Duration _snapDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 700), _hideFab);
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  void _hideFab() {
    if (!mounted || _isOpen || _isHalfHidden) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isHalfHidden = true;
      _snapDuration = const Duration(milliseconds: 300);
      
      final centerX = _left + 28;
      if (centerX < screenWidth / 2) {
        _left = -28;
      } else {
        _left = screenWidth - 28;
      }
    });
  }

  void _unhideFab() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isHalfHidden = false;
      _snapDuration = const Duration(milliseconds: 300);
      
      if (_left < 0) {
        _left = 16.0; 
      } else if (_left > screenWidth - 56) {
        _left = screenWidth - 72.0; 
      }
    });
    _startHideTimer();
  }

  void _toggleMenu() {
    if (_isHalfHidden) {
      _unhideFab();
      return;
    }

    _cancelHideTimer();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
        _startHideTimer();
      }
    });
  }

  void _navigateTo(Widget screen) {
    _toggleMenu();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Widget targetScreen,
      int index, double expandValue, double angleToCenter) {
    const double radius = 90.0;
    // Half circle: 3 items spread across 180 degrees pointing to the screen center
    double baseAngle = angleToCenter - (math.pi / 2);
    double itemAngle = baseAngle + (index * math.pi / 2);

    // Smooth rotational entry animation
    double currentAngle = itemAngle - (1.0 - expandValue) * 0.5;
    double currentRadius = radius * expandValue;

    double centerX = _left + 28;
    double centerY = _top + 28;

    double dx = currentRadius * math.cos(currentAngle);
    double dy = currentRadius * math.sin(currentAngle);

    return Positioned(
      left: centerX + dx,
      top: centerY + dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.scale(
          scale: expandValue,
          child: Opacity(
            opacity: expandValue.clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'menu_item_$index',
                  backgroundColor: AppColors.surfaceCard,
                  foregroundColor: AppColors.lightCyan,
                  elevation: 4,
                  onPressed: () => _navigateTo(targetScreen),
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_left == -1) {
      _left = 20;
      _top = 100;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = _left + 28;
    final centerY = _top + 28;
    // Angle pointing towards the center of the screen
    final angleToCenter = math.atan2(screenHeight / 2 - centerY, screenWidth / 2 - centerX);

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Blur
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final expandValue = _expandAnimation.value;
              if (expandValue == 0.0) return const SizedBox.shrink();

              return Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_isOpen) _toggleMenu();
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10.0 * expandValue,
                      sigmaY: 10.0 * expandValue,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3 * expandValue),
                    ),
                  ),
                ),
              );
            },
          ),
          // Menu items
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final expandValue = _expandAnimation.value;
              if (expandValue == 0.0) return const SizedBox.shrink();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildMenuItem(Icons.folder_open_rounded, 'Workspace',
                      const WorkspaceScreen(), 0, expandValue, angleToCenter),
                  _buildMenuItem(Icons.check_circle_outline_rounded, 'Task Manager',
                      const TaskManagerScreen(), 1, expandValue, angleToCenter),
                  _buildMenuItem(Icons.home_rounded, 'Home Dashboard',
                      const HomeDashboardScreen(), 2, expandValue, angleToCenter),
                ],
              );
            },
          ),
          // Main FAB
          AnimatedPositioned(
            duration: _snapDuration,
            curve: Curves.easeOutCubic,
            left: _left,
            top: _top,
            child: GestureDetector(
              onPanStart: (_) {
                _cancelHideTimer();
                setState(() {
                  _isHalfHidden = false;
                  _snapDuration = Duration.zero;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _left += details.delta.dx;
                  _top += details.delta.dy;
                  _top = _top.clamp(0.0, screenHeight - 56.0);
                });
              },
              onPanEnd: (_) {
                if (!_isOpen) _startHideTimer();
              },
              onPanCancel: () {
                if (!_isOpen) _startHideTimer();
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isHalfHidden ? 0.6 : 1.0,
                child: FloatingActionButton(
                  heroTag: 'main_fab',
                  backgroundColor:
                      _isOpen ? AppColors.surfaceCard : AppColors.lightCyan,
                  foregroundColor: _isOpen ? AppColors.lightCyan : Colors.black,
                  elevation: 6,
                  shape: const CircleBorder(),
                  onPressed: _toggleMenu,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: _isOpen
                        ? const Icon(Icons.close_rounded, size: 28, key: ValueKey('close'))
                        : SvgPicture.asset(
                            'assets/logos/QA.svg',
                            width: 28,
                            height: 28,
                            key: const ValueKey('svg'),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
