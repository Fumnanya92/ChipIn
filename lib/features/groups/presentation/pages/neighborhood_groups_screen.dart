import 'package:cached_network_image/cached_network_image.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ── Local dark surface colors (GitHub-style — not added to AppColors) ─────────
const Color _surfaceDark = Color(0xFF161B22);
const Color _borderDark = Color(0xFF30363D);
const Color _bgDark = Color(0xFF0D1117);

// ── Model ─────────────────────────────────────────────────────────────────────

class _Group {
  final String id;
  final String name;
  final String category;
  final int memberCount;
  final int newPosts;
  final String distance;
  final bool isJoined;
  final bool isActive;
  final bool isTopRated;
  final String? lastActive;

  const _Group({
    required this.id,
    required this.name,
    required this.category,
    required this.memberCount,
    required this.newPosts,
    required this.distance,
    this.isJoined = false,
    this.isActive = false,
    this.isTopRated = false,
    this.lastActive,
  });
}

// ── Mock data (replace with Supabase neighborhood_groups when ready) ───────────

const _joined = [
  _Group(
    id: 'g1',
    name: 'The Zenith',
    category: 'Building splits',
    memberCount: 24,
    newPosts: 3,
    distance: '0.1 mi',
    isJoined: true,
    isActive: true,
  ),
  _Group(
    id: 'g2',
    name: 'Oak Ridge Lane',
    category: 'Street sharing',
    memberCount: 14,
    newPosts: 1,
    distance: '0.3 mi',
    isJoined: true,
    lastActive: '2h ago',
  ),
  _Group(
    id: 'g3',
    name: 'Green Park Hub',
    category: 'Local services',
    memberCount: 8,
    newPosts: 0,
    distance: '0.6 mi',
    isJoined: true,
    lastActive: 'Yesterday',
  ),
];

const _nearby = [
  _Group(
    id: 'g4',
    name: 'Riverway Estates',
    category: 'Building splits',
    memberCount: 142,
    newPosts: 24,
    distance: '0.4 mi',
    isTopRated: true,
  ),
  _Group(
    id: 'g5',
    name: 'Skyline Plaza',
    category: 'Building splits',
    memberCount: 310,
    newPosts: 12,
    distance: '1.2 mi',
  ),
  _Group(
    id: 'g6',
    name: 'Harborview Heights',
    category: 'Street sharing',
    memberCount: 67,
    newPosts: 5,
    distance: '1.8 mi',
  ),
];

// Category filter items: (label, icon)
const _catItems = <(String, IconData?)>[
  ('All', null),
  ('Building splits', Icons.domain_rounded),
  ('Street sharing', Icons.share_location_rounded),
  ('Local services', Icons.handshake_rounded),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class NeighborhoodGroupsScreen extends StatefulWidget {
  const NeighborhoodGroupsScreen({super.key});

  @override
  State<NeighborhoodGroupsScreen> createState() =>
      _NeighborhoodGroupsScreenState();
}

class _NeighborhoodGroupsScreenState
    extends State<NeighborhoodGroupsScreen> {
  String _selectedCat = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Group> get _filteredNearby {
    final q = _searchCtrl.text.toLowerCase();
    return _nearby.where((g) {
      final catOk = _selectedCat == 'All' || g.category == _selectedCat;
      final qOk = q.isEmpty || g.name.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _bgDark : AppColors.backgroundLight,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: isDark ? _bgDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? AppColors.textDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        title: Text(
          'Neighborhood Groups',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showComingSoon('Create group'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showComingSoon('Create group'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),

      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // ── Search bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? _surfaceDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? _borderDark : AppColors.borderLight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search groups…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category filter pills ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _catItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (label, icon) = _catItems[i];
                  final selected = label == _selectedCat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 0),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : isDark
                                ? _surfaceDark
                                : const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : isDark
                                  ? _borderDark
                                  : AppColors.borderLight,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : isDark
                                      ? AppColors.textSubtle
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : isDark
                                      ? AppColors.textSubtle
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── "Joined Groups" header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Joined Groups',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showComingSoon('View all groups'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Joined group cards (horizontal scroll) ────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 182,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                itemCount: _joined.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _JoinedGroupCard(group: _joined[i], isDark: isDark),
              ),
            ),
          ),

          // ── "Recommended Nearby" header ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Text(
                'Recommended Nearby',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // ── Nearby group cards ────────────────────────────────────────────
          if (_filteredNearby.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No groups found',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _NearbyGroupCard(
                      group: _filteredNearby[i],
                      isDark: isDark,
                      onJoin: () => _showComingSoon('Join group'),
                    ),
                  ),
                  childCount: _filteredNearby.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Joined Group Thumbnail Card ───────────────────────────────────────────────

class _JoinedGroupCard extends StatelessWidget {
  final _Group group;
  final bool isDark;

  const _JoinedGroupCard({required this.group, required this.isDark});

  IconData get _icon {
    switch (group.category) {
      case 'Building splits':
        return Icons.domain_rounded;
      case 'Street sharing':
        return Icons.share_location_rounded;
      default:
        return Icons.handshake_rounded;
    }
  }

  // Generate overlapping mini avatar widgets
  List<Widget> _buildAvatars() {
    final count = group.memberCount > 12
        ? 3
        : group.memberCount > 5
            ? 2
            : 1;
    final avatarColors = [
      const Color(0xFF94A3B8),
      const Color(0xFF64748B),
      AppColors.primary,
    ];
    final extras = group.memberCount > 3 ? group.memberCount - 2 : 0;
    final List<Widget> widgets = [];
    for (int i = 0; i < count; i++) {
      final isLast = i == count - 1 && extras > 0;
      widgets.add(
        Transform.translate(
          offset: Offset(i * -7.0, 0),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isLast ? AppColors.primary : avatarColors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: _surfaceDark,
                width: 2,
              ),
            ),
            child: isLast
                ? Center(
                    child: Text(
                      '+$extras',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg =
        isDark ? const Color(0xFF1A2535) : const Color(0xFFE2E8F0);

    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square thumbnail with gradient + mini avatars
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background photo
                CachedNetworkImage(
                  imageUrl:
                      'https://picsum.photos/seed/${group.name.replaceAll(' ', '')}/300/300',
                  width: 128,
                  height: 128,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 128,
                    height: 128,
                    color: cardBg,
                    child: Center(
                      child: Icon(
                        _icon,
                        size: 44,
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 128,
                    height: 128,
                    color: cardBg,
                    child: Center(
                      child: Icon(
                        _icon,
                        size: 44,
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay bottom → top
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.60),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),

                // Mini avatars — bottom-left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: SizedBox(
                    width: 52,
                    height: 20,
                    child: Stack(
                      children: _buildAvatars(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          // Group name
          Text(
            group.name,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Active / lastActive label
          Text(
            group.isActive
                ? 'Active now'
                : (group.lastActive ?? ''),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight:
                  group.isActive ? FontWeight.w600 : FontWeight.w400,
              color: group.isActive
                  ? AppColors.primary
                  : isDark
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nearby Group Card ─────────────────────────────────────────────────────────

class _NearbyGroupCard extends StatelessWidget {
  final _Group group;
  final bool isDark;
  final VoidCallback onJoin;

  const _NearbyGroupCard({
    required this.group,
    required this.isDark,
    required this.onJoin,
  });

  IconData get _icon {
    switch (group.category) {
      case 'Building splits':
        return Icons.domain_rounded;
      case 'Street sharing':
        return Icons.share_location_rounded;
      default:
        return Icons.handshake_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _borderDark : AppColors.borderLight,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image area ────────────────────────────────────────────────────
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl:
                    'https://picsum.photos/seed/${group.name.replaceAll(' ', '')}/600/300',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  width: double.infinity,
                  color: isDark
                      ? const Color(0xFF1A2535)
                      : const Color(0xFFE2E8F0),
                  child: Center(
                    child: Icon(
                      _icon,
                      size: 44,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  width: double.infinity,
                  color: isDark
                      ? const Color(0xFF1A2535)
                      : const Color(0xFFE2E8F0),
                  child: Center(
                    child: Icon(
                      _icon,
                      size: 44,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              if (group.isTopRated)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'TOP RATED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Card body ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Join button row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                group.distance,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textMuted
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Join button (rounded-full)
                    GestureDetector(
                      onTap: onJoin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Divider
                Divider(
                  height: 1,
                  color: isDark ? _borderDark : AppColors.borderLight,
                ),

                const SizedBox(height: 10),

                // Stats row
                Row(
                  children: [
                    const Icon(
                      Icons.group_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount} members',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.forum_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.newPosts} new posts',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
