import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:chipin/shared/widgets/error_retry.dart';
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
    _TrendingCat('Travel', 'carpool', Icons.directions_car_rounded),
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
    final userId = ref.watch(currentUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Icon button bg: dark = cardTeal, light = slate-100
    final iconBtnBg = isDark ? AppColors.cardTeal : const Color(0xFFF1F5F9);
    final iconBtnColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Logo circle
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ChipIn',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Search button
              GestureDetector(
                onTap: () => context.go('/browse'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBtnBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search_rounded,
                      size: 20, color: iconBtnColor),
                ),
              ),
              const SizedBox(width: 8),
              // Bell button with primary badge
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBtnBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_outlined,
                          size: 20, color: iconBtnColor),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Auth CTA bar — only shown for guests ────────────────────────────
      bottomNavigationBar: userId == null
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Get Started'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,

      body: CustomScrollView(
        slivers: [
          // ── Community Stats ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: listingsAsync.when(
                loading: () =>
                    _StatsGrid.placeholder(isDark: isDark),
                error: (e, s) => const SizedBox.shrink(),
                data: (listings) =>
                    _StatsGrid(listings: listings, isDark: isDark),
              ),
            ),
          ),

          // ── Trending Categories ──────────────────────────────────────────
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
                      color: isDark ? AppColors.textDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _trendingCategories.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(width: 8),
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
                                : isDark
                                    ? AppColors.cardTeal
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
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
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Latest Opportunities header ──────────────────────────────────
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
                      color:
                          isDark ? AppColors.textDark : AppColors.textPrimary,
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

          // ── Feed cards ──────────────────────────────────────────────────
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
              child: ErrorRetry(
                error: e,
                onRetry: () => ref.invalidate(listingsProvider),
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
                        listing: listings[i],
                        isDark: isDark,
                      ),
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

// ── Stats Grid ─────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final List<ListingModel> listings;
  final bool isDark;
  const _StatsGrid({required this.listings, required this.isDark});

  factory _StatsGrid.placeholder({required bool isDark}) =>
      _StatsGrid(listings: const [], isDark: isDark);

  int get _totalPeopleHelped =>
      listings.fold(0, (sum, l) => sum + l.slotsFilled);

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        'Active Splits',
        '${listings.isEmpty ? '—' : listings.length}',
        listings.isEmpty ? 0.0 : 0.66,
        false,
        isDark,
      ),
      _StatItem(
        'People Helped',
        '$_totalPeopleHelped+',
        listings.isEmpty ? 0.0 : 0.5,
        false,
        isDark,
      ),
      _StatItem('Total Saved', '₦2.4M', 1.0, true, isDark),
      _StatItem('Trust Score', '100', 0.8, false, isDark),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
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
    final accent = success ? AppColors.statusActive : AppColors.primary;
    final cardBg = isDark ? AppColors.cardTeal : Colors.white;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 4,
          ),
        ],
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
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

// ── Feed Card ──────────────────────────────────────────────────────────────────

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
        return '₦$s/mo';
      case ListingDuration.oneTime:
      case ListingDuration.custom:
        return '₦$s/pp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final isDark = widget.isDark;
    final cardBg = isDark ? AppColors.cardTeal : Colors.white;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
          // ── Header row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: l.posterAvatarUrl != null
                        ? Image.network(
                            l.posterAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              color: AppColors.primaryLight,
                              child: Center(
                                child: Text(
                                  (l.posterName ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primaryLight,
                            child: Center(
                              child: Text(
                                (l.posterName ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + time + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + verified check
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              l.posterName ?? 'Anonymous',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Time + category tag
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: mutedColor,
                          ),
                          children: [
                            TextSpan(
                                text:
                                    '${timeago.format(l.createdAt)} • '),
                            TextSpan(
                              text: '[${l.category.label}]',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating pill
                if (l.posterTrustScore != null) ...[
                  const SizedBox(width: 8),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.starColor),
                        const SizedBox(width: 3),
                        Text(
                          (l.posterTrustScore! / 20)
                              .toStringAsFixed(1),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Title ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Text(
              l.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Location ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Icon(
                  l.isRemote
                      ? Icons.public_rounded
                      : Icons.location_on_rounded,
                  size: 14,
                  color: mutedColor,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    l.isRemote ? 'Digital / Global' : l.location,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: mutedColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Verification badges ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _VerificationBadge('✓ ID Verified'),
                _VerificationBadge('✓ Phone Verified'),
                if ((l.posterTrustScore ?? 0) > 60)
                  _VerificationBadge('✓ Trusted'),
              ],
            ),
          ),

          // ── Price + availability box ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderSlate
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  // Price
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
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Availability
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
                            ? '${l.slotsLeft} spot${l.slotsLeft == 1 ? '' : 's'} left'
                            : 'Full',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
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

          // ── CTA button ────────────────────────────────────────────────────
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
                  elevation: 0,
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

          // ── Social footer ─────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () => setState(() => _liked = !_liked),
                  child: Row(
                    children: [
                      Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: _liked ? Colors.red : mutedColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_liked ? 1 : 0}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Comment
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 20, color: mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      '0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Bookmark
                GestureDetector(
                  onTap: () =>
                      setState(() => _bookmarked = !_bookmarked),
                  child: Icon(
                    _bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 20,
                    color: _bookmarked ? AppColors.primary : mutedColor,
                  ),
                ),
                const SizedBox(width: 14),
                // Share
                Icon(Icons.share_rounded, size: 20, color: mutedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verification badge chip ────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  final String label;
  const _VerificationBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
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

// ── Feed card skeleton ────────────────────────────────────────────────────────

class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? const Color(0xFF1A2E32) : const Color(0xFFE2E8F0);
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── Trending category data ─────────────────────────────────────────────────────

class _TrendingCat {
  final String label;
  final String? value;
  final IconData icon;
  const _TrendingCat(this.label, this.value, this.icon);
}
