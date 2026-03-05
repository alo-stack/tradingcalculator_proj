import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<NavItemData> _navItems = [
    NavItemData(icon: Icons.calculate, label: 'Calculators'),
    NavItemData(icon: Icons.newspaper, label: 'News'),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.selectionClick();
    
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      context.go('/calculators');
    } else if (index == 1) {
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
          // Bottom navigation bar - centered with breathing room
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _navItems.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _NavItem(
                        icon: _navItems[index].icon,
                        label: _navItems[index].label,
                        isActive: _currentIndex == index,
                        onTap: () => _onTabTapped(index),
                      ),
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

class NavItemData {
  final IconData icon;
  final String label;

  NavItemData({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: AppRadius.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.accent : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.text(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}