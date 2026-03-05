import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.selectionClick();
    
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      context.go('/calculators');
    } else {
      context.go('/news');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current index from route
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calculators')) {
      _currentIndex = 0;
    } else if (location.startsWith('/news')) {
      _currentIndex = 1;
    }

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          // Floating pill navbar
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 56,
                width: 220,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavItem(
                      icon: Icons.calculate_outlined,
                      isActive: _currentIndex == 0,
                      onTap: () => _onTabTapped(0),
                    ),
                    const SizedBox(width: 20),
                    _NavItem(
                      icon: Icons.newspaper_outlined,
                      isActive: _currentIndex == 1,
                      onTap: () => _onTabTapped(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active indicator — 3px orange pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 16 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: AppRadius.pill,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            icon,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            size: 24,
          ),
        ],
      ),
    );
  }
}