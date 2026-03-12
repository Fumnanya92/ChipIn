import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

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

// ── Mock data (replace with Supabase neighborhood_groups table when ready) ─────

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

const _categories = [
  'All',
  'Building splits',
  'Street sharing',
  'Local services',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class NeighborhoodGroupsScreen extends StatefulWidget {
  const NeighborhoodGroupsScreen({super.key});

  @override
  State<NeighborhoodGroupsScreen> createState() =>
      _NeighborhoodGroupsScreenState();
}

class _NeighborhoodGroupsScreenState extends State<NeighborhoodGroupsScreen> {
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
      final catOk =
          _selectedCat == 'All' || g.category == _selectedCat;
      final qOk =
          q.isEmpty || g.name.toLowerCase().contains(q);
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
      appBar: AppBar(
        title: const Text('Neighborhood Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create group',
            onPressed: () => _showComingSoon('Create group'),
          ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComingSoon('Create group'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),

      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // ── Search bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search neighborhoods…',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textMuted,
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

          // ── Category chips ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border(context),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : isDark
                                  ? const Color(0xFFCBD5E1)
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Joined Groups ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Joined Groups',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : AppColors.textPrimary,
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

          SliverToBoxAdapter(
            child: SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _joined.length,
                separatorBuilder: (context, i) => const SizedBox(width: 14),
                itemBuilder: (context, i) =>
                    _JoinedGroupCard(group: _joined[i], isDark: isDark),
              ),
            ),
          ),

          // ── Recommended Nearby ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Recommended Nearby',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          if (_filteredNearby.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No groups found for "$_selectedCat"',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textSecondary),
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

// ── Joined Group Thumbnail ────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Center(
                  child: Icon(_icon,
                      size: 40,
                      color: AppColors.primary.withValues(alpha: 0.7)),
                ),
              ),
              if (group.isActive)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Active now',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
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
          Text(
            group.lastActive ?? (group.isActive ? 'Active now' : ''),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: group.isActive
                  ? AppColors.primary
                  : isDark
                      ? const Color(0xFF94A3B8)
                      : AppColors.textSecondary,
              fontWeight: group.isActive ? FontWeight.w600 : FontWeight.w400,
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
  const _NearbyGroupCard(
      {required this.group, required this.isDark, required this.onJoin});

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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Stack(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF1A2E32)
                    : const Color(0xFFE2E8F0),
                child: Center(
                  child: Icon(_icon,
                      size: 44,
                      color: AppColors.primary.withValues(alpha: 0.5)),
                ),
              ),
              if (group.isTopRated)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                group.distance,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Join'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                    height: 1,
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.group_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount} members',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.forum_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${group.newPosts} new posts',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
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
