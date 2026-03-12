import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppShell({required this.shell, super.key});

  // Map shell branch index → bottom nav row index (skip index 2 = FAB slot)
  // Branches: 0=Home, 1=Explore, 2=Matches, 3=Messages, 4=Profile
  // NavBar:   0=Home, 1=Explore, 2=FAB,     3=Matches, 4=Messages, 5=Profile
  int get _navIndex {
    if (shell.currentIndex >= 2) return shell.currentIndex + 1;
    return shell.currentIndex;
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // If not on first tab, go to first tab instead of exiting
        if (shell.currentIndex != 0) {
          shell.goBranch(0, initialLocation: true);
          return;
        }
        // On home tab — ask user to confirm exit
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit ChipIn?'),
            content: const Text('Are you sure you want to leave?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          // Allow the system to handle the back (exit)
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                icon: Icons.chat_bubble_rounded,
                label: 'Messages',
                active: _navIndex == 4,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleNav(context, 4),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: _navIndex == 5,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _handleNav(context, 5),
              ),
            ],
          ),
        ),
      ),
    ),   // end Scaffold (child of PopScope)
    );   // end PopScope
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
