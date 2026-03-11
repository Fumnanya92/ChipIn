import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppShell({required this.shell, super.key});

  // Map shell branch index → bottom nav row index (skip index 2 = FAB slot)
  int get _navIndex {
    return shell.currentIndex >= 2 ? shell.currentIndex + 1 : shell.currentIndex;
  }

  void _handleNav(BuildContext context, int tapIndex) {
    if (tapIndex == 2) {
      // FAB tapped — navigate to Post wizard
      context.push('/post/category');
      return;
    }
    final branchIndex = tapIndex > 2 ? tapIndex - 1 : tapIndex;
    shell.goBranch(
      branchIndex,
      initialLocation: branchIndex == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textMuted;

    return Scaffold(
      body: shell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post/category'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: bgColor,
        elevation: 8,
        shadowColor: Colors.black12,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: _navIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleNav(context, 0),
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Explore',
                active: _navIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleNav(context, 1),
              ),
              // Centre gap for FAB
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.handshake_rounded,
                label: 'Matches',
                active: _navIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleNav(context, 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: _navIndex == 4,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleNav(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24, color: active ? activeColor : inactiveColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
