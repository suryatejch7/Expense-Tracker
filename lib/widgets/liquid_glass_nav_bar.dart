import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/quick_action_item.dart';
import '../widgets/glass_bottom_sheet.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/crop_calibration_screen.dart';

class GlassNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _highlightController;
  late AnimationController _activeController;
  late AnimationController _swipeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _highlightAnimation;
  late Animation<double> _activeAnimation;
  late Animation<double> _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _activeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOutCubic,
    ));

    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    ));

    _activeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _activeController,
      curve: Curves.easeInOutCubic,
    ));

    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _highlightController.dispose();
    _activeController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    _pressController.forward();
    _highlightController.forward();
  }

  void _onTapUp(int index) {
    _pressController.reverse();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _highlightController.reverse();
      }
    });

    widget.onTap(index);
  }

  void _onTapCancel() {
    _pressController.reverse();
    _highlightController.reverse();
  }

  void _showQuickActions(int index) {
    final items = _getQuickActionItems(index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => GlassBottomSheet(items: items),
    );
  }

  List<QuickActionItem> _getQuickActionItems(int index) {
    if (index == 0) {
      return [
        QuickActionItem(
          id: 'search',
          icon: Icons.search,
          title: 'Search',
          subtitle: 'Find specific expenses',
          color: Colors.blue,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        QuickActionItem(
          id: 'settings',
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App preferences',
          color: Colors.grey,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ];
    } else {
      return [
        QuickActionItem(
          id: 'analytics',
          icon: Icons.pie_chart_outline,
          title: 'Analytics',
          subtitle: 'View spending insights',
          color: Colors.purple,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
            );
          },
        ),
        QuickActionItem(
          id: 'crop_calibration',
          icon: Icons.crop_free,
          title: 'Crop Calibration',
          subtitle: 'Calibrate PhonePe OCR',
          color: Colors.orange,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CropCalibrationScreen()),
            );
          },
        ),
      ];
    }
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    const double swipeThreshold = 100.0;

    if (details.primaryVelocity!.abs() > swipeThreshold) {
      if (details.primaryVelocity! > 0) {
        // Swipe right: Home (0) → Categories (1)
        if (widget.currentIndex == 0) {
          _animateSwipeTransition(1);
        }
      } else {
        // Swipe left: Categories (1) → Home (0)
        if (widget.currentIndex == 1) {
          _animateSwipeTransition(0);
        }
      }
    }
  }

  void _animateSwipeTransition(int newIndex) {
    _swipeController.forward().then((_) {
      widget.onTap(newIndex);
      _swipeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation, 
            _swipeAnimation
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * 0.9, // Scale down the nav bar
              child: GestureDetector(
                onHorizontalDragEnd: _handleHorizontalSwipe,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 15, 
                      sigmaY: 15
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 70,
                      width: 200,
                      transform: Matrix4.identity()
                        ..setTranslationRaw(_swipeAnimation.value * 10 * (widget.currentIndex == 0 ? 1 : -1), 0, 0)
                        ..scaleByVector3(vmath.Vector3.all(1.0 + (_swipeAnimation.value * 0.015))),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.15 + (_swipeAnimation.value * 0.05)),
                            Colors.white.withValues(alpha: 0.08 + (_swipeAnimation.value * 0.03)),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20 + (_swipeAnimation.value * 10),
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 40 + (_swipeAnimation.value * 20),
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Icons.dashboard_rounded,
                            activeIcon: Icons.dashboard,
                            label: 'Home',
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.pie_chart_outline_rounded,
                            activeIcon: Icons.pie_chart_rounded,
                            label: 'Categories',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = widget.currentIndex == index;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _highlightAnimation,
        _activeAnimation,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => _onTapDown(index),
          onTapUp: (_) => _onTapUp(index),
          onTapCancel: _onTapCancel,
          onLongPress: () => _showQuickActions(index),
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              // Swipe up detected
              _showQuickActions(index);
            }
          },
          onHorizontalDragEnd: _handleHorizontalSwipe,
          child: Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: isActive
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              ),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
