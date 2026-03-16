import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — root scaffold with Magic Navigation Menu 3 indicator
// Branches: 0=Home  1=Explore  2=Matches  3=Profile
// NavRow:   0=Home  1=Explore  2=Post(action) 3=Matches  4=Profile
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  final StatefulNavigationShell shell;
  const AppShell({required this.shell, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _postActive = false;

  // Map shell branch index → nav row index (skip slot 2 = Post)
  int get _navIndex {
    if (widget.shell.currentIndex >= 2) return widget.shell.currentIndex + 1;
    return widget.shell.currentIndex;
  }

  // When Post is active, override indicator to slot 2
  int get _effectiveNavIndex => _postActive ? 2 : _navIndex;

  Future<void> _handleNav(BuildContext context, int tapIndex) async {
    if (tapIndex == 2) {
      setState(() => _postActive = true);
      await context.push('/post/category');
      if (mounted) setState(() => _postActive = false);
      return;
    }
    if (_postActive) setState(() => _postActive = false);
    final branchIndex = tapIndex > 2 ? tapIndex - 1 : tapIndex;
    widget.shell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF162024) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (widget.shell.currentIndex != 0) {
          widget.shell.goBranch(0, initialLocation: true);
          return;
        }
        final exit = await showDialog<bool>(
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
        if (exit == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: widget.shell,
        bottomNavigationBar: _MagicNavBar(
          activeNavIndex: _effectiveNavIndex,
          onTap: (i) => _handleNav(context, i),
          navBg: navBg,
          borderColor: borderColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Magic Nav Bar — sliding circular indicator, icon lift, label fade
// ─────────────────────────────────────────────────────────────────────────────

class _MagicNavBar extends StatelessWidget {
  final int activeNavIndex;
  final void Function(int) onTap;
  final Color navBg;
  final Color borderColor;

  static const double _navH = 60.0;
  static const double _indicatorD = 56.0;
  static const double _overflow = 28.0; // = _indicatorD/2
  static const double _totalH = _navH + _overflow;

  const _MagicNavBar({
    required this.activeNavIndex,
    required this.onTap,
    required this.navBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final slotW = constraints.maxWidth / 5;
        final targetX = (activeNavIndex + 0.5) * slotW;

        return SizedBox(
          height: _totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Nav background
              Positioned(
                left: 0,
                right: 0,
                top: _overflow,
                height: _navH,
                child: Container(
                  decoration: BoxDecoration(
                    color: navBg,
                    border: Border(
                      top: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                ),
              ),

              // Sliding indicator circle
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: targetX),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOutCubic,
                builder: (_, animX, _) {
                  final circleTop = _overflow - _indicatorD / 2;
                  return Positioned(
                    left: animX - _indicatorD / 2,
                    top: circleTop,
                    child: _IndicatorCircle(navBg: navBg),
                  );
                },
              ),

              // Icons row
              Positioned(
                left: 0,
                right: 0,
                top: _overflow,
                height: _navH,
                child: Row(
                  children: [
                    _NavSlot(
                      icon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                      label: 'Home',
                      active: activeNavIndex == 0,
                      onTap: () => onTap(0),
                      slotW: slotW,
                    ),
                    _NavSlot(
                      icon: Icons.explore_rounded,
                      inactiveIcon: Icons.explore_outlined,
                      label: 'Explore',
                      active: activeNavIndex == 1,
                      onTap: () => onTap(1),
                      slotW: slotW,
                    ),
                    // Post — participates in circle animation like others
                    _NavSlot(
                      icon: Icons.add_circle_rounded,
                      inactiveIcon: Icons.add_circle_outline_rounded,
                      label: 'Post',
                      active: activeNavIndex == 2,
                      onTap: () => onTap(2),
                      slotW: slotW,
                      alwaysPrimary: true,
                    ),
                    _NavSlot(
                      icon: Icons.handshake_rounded,
                      inactiveIcon: Icons.handshake_outlined,
                      label: 'Matches',
                      active: activeNavIndex == 3,
                      onTap: () => onTap(3),
                      slotW: slotW,
                    ),
                    _NavSlot(
                      icon: Icons.person_rounded,
                      inactiveIcon: Icons.person_outline_rounded,
                      label: 'Profile',
                      active: activeNavIndex == 4,
                      onTap: () => onTap(4),
                      slotW: slotW,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicator circle widget
// ─────────────────────────────────────────────────────────────────────────────

class _IndicatorCircle extends StatelessWidget {
  final Color navBg;
  static const double _d = _MagicNavBar._indicatorD;

  const _IndicatorCircle({required this.navBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _d,
      height: _d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: navBg,
        border: Border.all(color: AppColors.primary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav slot — icon lifts into indicator circle when active
// alwaysPrimary: keeps icon/label primary color even when inactive (Post)
// ─────────────────────────────────────────────────────────────────────────────

class _NavSlot extends StatelessWidget {
  final IconData icon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final double slotW;
  final bool alwaysPrimary;

  const _NavSlot({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.slotW,
    this.alwaysPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        (active || alwaysPrimary) ? AppColors.primary : AppColors.textSecondary;
    final labelColor =
        alwaysPrimary ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: slotW,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSlide(
              offset: active ? const Offset(0, -1.05) : Offset.zero,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                scale: active ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: Icon(
                  active ? icon : inactiveIcon,
                  size: 23,
                  color: iconColor,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: active ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Transform.translate(
                offset: const Offset(0, 3),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight:
                        alwaysPrimary ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
