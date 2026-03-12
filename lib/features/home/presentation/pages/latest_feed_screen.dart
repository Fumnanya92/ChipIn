import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class LatestFeedScreen extends ConsumerStatefulWidget {
  const LatestFeedScreen({super.key});

  @override
  ConsumerState<LatestFeedScreen> createState() => _LatestFeedScreenState();
}

class _LatestFeedScreenState extends ConsumerState<LatestFeedScreen> {
  String? _selectedCategory;

  static const _trendingCategories = [
    _TrendingCat('All', null, Icons.apps_rounded),
    _TrendingCat('Apartment', 'apartment', Icons.apartment_rounded),
    _TrendingCat('Subscription', 'subscription', Icons.subscriptions_rounded),
    _TrendingCat('Travel', 'carpool', Icons.flight_rounded),
    _TrendingCat('Workspaces', 'office', Icons.work_rounded),
    _TrendingCat('Groceries', 'groceries', Icons.local_grocery_store_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(
      _selectedCategory == null
          ? listingsProvider
          : listingsByCategoryProvider(_selectedCategory),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'ChipIn',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Community Stats ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: listingsAsync.when(
                loading: () => _StatsGrid.placeholder(isDark: isDark),
                error: (e, s) => const SizedBox.shrink(),
                data: (listings) => _StatsGrid(
                  listings: listings,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // ── Trending Categories ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'Trending Categories',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _trendingCategories.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _trendingCategories[i];
                      final selected = cat.value == _selectedCategory;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border(context),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Icon(
                                cat.icon,
                                size: 15,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Latest Opportunities header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Latest Opportunities',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/browse'),
                    child: const Text(
                      'View all',
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

          // ── Feed cards ─────────────────────────────────────────────────
          listingsAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _FeedCardSkeleton(),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: Text('Could not load: $e',
                        style: const TextStyle(
                            color: AppColors.textSecondary))),
              ),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 52,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCategory == null
                              ? 'No listings yet.\nBe the first to post a split!'
                              : 'No listings in this category.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _FeedCard(
                          listing: listings[i], isDark: isDark),
                    ),
                    childCount: listings.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final List<ListingModel> listings;
  final bool isDark;
  const _StatsGrid({required this.listings, required this.isDark});

  factory _StatsGrid.placeholder({required bool isDark}) =>
      _StatsGrid(listings: const [], isDark: isDark);

  int get _totalSlots =>
      listings.fold(0, (sum, l) => sum + l.slotsFilled);

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Active Users', '12k+', 0.75, false, isDark),
      _StatItem('Matches', '$_totalSlots+', 0.5, false, isDark),
      _StatItem('Listings', '${listings.length}', listings.isEmpty ? 0.0 : 0.66, false, isDark),
      _StatItem('Total Saved', r'$2.4M', 1.0, true, isDark),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final double fill;
  final bool success;
  final bool isDark;
  const _StatItem(
      this.label, this.value, this.fill, this.success, this.isDark);

  @override
  Widget build(BuildContext context) {
    final accent = success ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 4,
              backgroundColor: accent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed Card ─────────────────────────────────────────────────────────────────

class _FeedCard extends ConsumerStatefulWidget {
  final ListingModel listing;
  final bool isDark;
  const _FeedCard({required this.listing, required this.isDark});

  @override
  ConsumerState<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<_FeedCard> {
  bool _liked = false;
  bool _bookmarked = false;

  String get _priceLabel {
    final a = widget.listing.splitAmount;
    final s = a.truncateToDouble() == a
        ? a.toStringAsFixed(0)
        : a.toStringAsFixed(2);
    switch (widget.listing.duration) {
      case ListingDuration.monthly:
        return '\$$s/mo';
      case ListingDuration.oneTime:
      case ListingDuration.custom:
        return '\$$s/pp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final isDark = widget.isDark;
    final cardBg = AppColors.surface(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: l.posterAvatarUrl != null
                      ? NetworkImage(l.posterAvatarUrl!)
                      : null,
                  child: l.posterAvatarUrl == null
                      ? Text(
                          (l.posterName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l.posterName ?? 'Anonymous',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                      Text(
                        '${timeago.format(l.createdAt)} • ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                if (l.posterTrustScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${l.posterTrustScore!.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Title + location ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      l.isRemote
                          ? Icons.public_rounded
                          : Icons.location_on_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        l.isRemote ? 'Digital / Global' : l.location,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Verification badges ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Wrap(
              spacing: 6,
              children: [
                _Badge('✓ ID Verified'),
                if ((l.posterTrustScore ?? 0) > 60) _Badge('✓ Trusted'),
              ],
            ),
          ),

          // ── Price + slots ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x1A000000)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2D4A50)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRICE PER PERSON',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _priceLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'AVAILABILITY',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.slotsLeft > 0
                            ?               '${l.slotsLeft} spot${l.slotsLeft == 1 ? '' : 's'} left'
                            : 'Full',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: l.slotsLeft > 0
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── CTA ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) {
                    context.push('/login');
                  } else {
                    context.push('/listing/${l.id}');
                  }
                },
                icon: const Icon(Icons.handshake_rounded, size: 18),
                label: const Text('Request to Split'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Social actions ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x0DFFFFFF)
                  : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: AppColors.border(context)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _liked = !_liked),
                        child: Row(
                          children: [
                            Icon(
                              _liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: _liked
                                  ? Colors.red
                                  : isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_liked ? 1 : 0}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '0',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _bookmarked = !_bookmarked),
                      child: Icon(
                        _bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: _bookmarked
                            ? AppColors.primary
                            : isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.share_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary),
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

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Skeleton placeholder ──────────────────────────────────────────────────────

class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? const Color(0xFF1E3438) : const Color(0xFFE2E8F0);
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── Trending category data ────────────────────────────────────────────────────

class _TrendingCat {
  final String label;
  final String? value;
  final IconData icon;
  const _TrendingCat(this.label, this.value, this.icon);
}
