import 'package:cached_network_image/cached_network_image.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:chipin/shared/widgets/error_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  bool _hasSearchText = false;

  static const _categories = [
    _Category('subscription', 'Subs', Icons.subscriptions_rounded,
        AppColors.catSubscription),
    _Category(
        'apartment', 'Housing', Icons.home_rounded, AppColors.catHousing),
    _Category('carpool', 'Travel', Icons.directions_car_rounded,
        AppColors.catTravel),
    _Category('groceries', 'Groceries', Icons.local_grocery_store_rounded,
        AppColors.catGroceries),
    _Category('office', 'Work', Icons.work_rounded, AppColors.catWork),
    _Category(
        'bills', 'Bills', Icons.receipt_long_rounded, AppColors.catBills),
    _Category('other', 'Other', Icons.more_horiz_rounded, AppColors.catOther),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasSearchText) setState(() => _hasSearchText = hasText);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_selectedCategory == null) {
      ref.invalidate(listingsProvider);
    } else {
      ref.invalidate(listingsByCategoryProvider(_selectedCategory));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = _selectedCategory == null
        ? ref.watch(listingsProvider)
        : ref.watch(listingsByCategoryProvider(_selectedCategory));
    final user = ref.watch(authNotifierProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg =
        isDark ? const Color(0xFF0F172A) : AppColors.surfaceLight;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Sticky AppBar + Search ──────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                automaticallyImplyLeading: false,
                backgroundColor: appBarBg,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 60,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Left: avatar / person icon
                      GestureDetector(
                        onTap: () => user != null
                            ? context.go('/me')
                            : context.go('/login'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _avatarWidget(user, isDark),
                          ),
                        ),
                      ),
                      // Center: ChipIn
                      const Expanded(
                        child: Center(
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
                      ),
                      // Right: messages icon + notification bell
                      GestureDetector(
                        onTap: () => context.push('/messages'),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 24,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 26,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textPrimary,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (q) {
                        if (q.isNotEmpty) context.go('/browse');
                      },
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search splits, categories…',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        suffixIcon: _hasSearchText
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.cardDark
                            : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Categories header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/browse'),
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

              // ── Category icons ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final selected = _selectedCategory == cat.key;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _selectedCategory = selected ? null : cat.key),
                        child: Container(
                          width: 80,
                          margin: EdgeInsets.only(
                              right: i < _categories.length - 1 ? 8 : 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cat.color.withValues(alpha: 0.2)
                                      : cat.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: selected
                                      ? Border.all(
                                          color: cat.color
                                              .withValues(alpha: 0.5),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  cat.icon,
                                  size: 24,
                                  color: cat.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textSubtle
                                      : AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Quick access banners ────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    children: [
                      _QuickBanner(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Smart Match',
                        sublabel: 'AI-curated splits',
                        gradient: const [Color(0xFF11B4D4), Color(0xFF0D8FAB)],
                        onTap: () => context.push('/smart-match'),
                      ),
                      const SizedBox(width: 12),
                      _QuickBanner(
                        icon: Icons.group_work_rounded,
                        label: 'Neighborhoods',
                        sublabel: 'Your local groups',
                        gradient: const [Color(0xFF1E3A50), Color(0xFF162A38)],
                        onTap: () => context.push('/groups'),
                      ),
                      const SizedBox(width: 12),
                      _QuickBanner(
                        icon: Icons.dynamic_feed_rounded,
                        label: 'Latest Feed',
                        sublabel: 'New opportunities',
                        gradient: const [Color(0xFF1A3B2E), Color(0xFF122A1F)],
                        onTap: () => context.push('/latest-feed'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Featured Splits header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Featured Splits',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/browse'),
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

              // ── Listings ────────────────────────────────────────────────
              listingsAsync.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ShimmerCard(isDark: isDark),
                    childCount: 4,
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
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No splits found',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSubtle
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Be the first to post a split!',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ListingCard(
                            listing: listings[i],
                            onTap: () =>
                                context.push('/listing/${listings[i].id}'),
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
        ),
      ),
    );
  }

  Widget _avatarWidget(dynamic user, bool isDark) {
    if (user == null) {
      return Container(
        color: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        child: Icon(
          Icons.person_rounded,
          size: 18,
          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
        ),
      );
    }
    if (user.avatarUrl != null) {
      return CachedNetworkImage(
        imageUrl: user.avatarUrl as String,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => Container(
          color: AppColors.primaryLight,
          child: const Icon(Icons.person_rounded,
              size: 18, color: AppColors.primary),
        ),
        errorWidget: (ctx, url, err) => Container(
          color: AppColors.primaryLight,
          child: Center(
            child: Text(
              (user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'C'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
    final name = user.displayName as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Category data ──────────────────────────────────────────────────────────────

class _Category {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _Category(this.key, this.label, this.icon, this.color);
}

// ── Listing Card ───────────────────────────────────────────────────────────────

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const ListingCard({super.key, required this.listing, required this.onTap});

  Color get _categoryColor {
    switch (listing.category) {
      case ListingCategory.subscription:
        return AppColors.catSubscription;
      case ListingCategory.apartment:
        return AppColors.catHousing;
      case ListingCategory.carpool:
        return AppColors.catTravel;
      case ListingCategory.groceries:
        return AppColors.catGroceries;
      case ListingCategory.office:
        return AppColors.catWork;
      case ListingCategory.bills:
        return AppColors.catBills;
      case ListingCategory.other:
        return AppColors.catOther;
    }
  }

  Color get _categoryBgColor {
    switch (listing.category) {
      case ListingCategory.subscription:
        return AppColors.catSubscriptionBg;
      case ListingCategory.apartment:
        return AppColors.catHousingBg;
      case ListingCategory.carpool:
        return AppColors.catTravelBg;
      case ListingCategory.groceries:
        return AppColors.catGroceriesBg;
      case ListingCategory.office:
        return AppColors.catWorkBg;
      case ListingCategory.bills:
        return AppColors.catBillsBg;
      case ListingCategory.other:
        return AppColors.catOtherBg;
    }
  }

  IconData get _categoryIcon {
    switch (listing.category) {
      case ListingCategory.subscription:
        return Icons.subscriptions_rounded;
      case ListingCategory.apartment:
        return Icons.home_rounded;
      case ListingCategory.carpool:
        return Icons.directions_car_rounded;
      case ListingCategory.groceries:
        return Icons.local_grocery_store_rounded;
      case ListingCategory.office:
        return Icons.work_rounded;
      case ListingCategory.bills:
        return Icons.receipt_long_rounded;
      case ListingCategory.other:
        return Icons.category_rounded;
    }
  }

  String get _priceLabel {
    final a = listing.splitAmount;
    final s = a.truncateToDouble() == a
        ? a.toStringAsFixed(0)
        : a.toStringAsFixed(2);
    switch (listing.duration) {
      case ListingDuration.monthly:
        return '₦$s/mo';
      case ListingDuration.oneTime:
        return '₦$s';
      case ListingDuration.custom:
        return '₦$s/pp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotsLeft = listing.slotsLeft;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor =
        isDark ? AppColors.borderSlate : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image with overlays ────────────────────────────────
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder
                  listing.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              Container(color: _categoryBgColor),
                          errorWidget: (ctx, url, err) => Container(
                            color: _categoryBgColor,
                            child: Center(
                              child: Icon(_categoryIcon,
                                  size: 48,
                                  color: _categoryColor
                                      .withValues(alpha: 0.4)),
                            ),
                          ),
                        )
                      : Container(
                          color: _categoryBgColor,
                          child: Center(
                            child: Icon(_categoryIcon,
                                size: 48,
                                color:
                                    _categoryColor.withValues(alpha: 0.4)),
                          ),
                        ),

                  // Gradient overlay (bottom dark → top transparent)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                    ),
                  ),

                  // Category badge — top left
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listing.category.label.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Title + price badge — bottom
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _priceLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User row + slots
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar size-8 (32px)
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: listing.posterAvatarUrl != null
                            ? NetworkImage(listing.posterAvatarUrl!)
                            : null,
                        child: listing.posterAvatarUrl == null
                            ? Text(
                                listing.posterName?.isNotEmpty == true
                                    ? listing.posterName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // Name + trust score
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.posterName ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (listing.posterTrustScore != null)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12,
                                      color: AppColors.starColor),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Trust Score: ${listing.posterTrustScore!.toInt()}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Slots — right aligned
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'SLOTS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            '${listing.slotsFilled}/${listing.slotsTotal}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: slotsLeft > 0 ? onTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.textMuted.withValues(alpha: 0.3),
                        elevation: 0,
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        slotsLeft > 0 ? 'Request to Split' : 'Full',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base =
        isDark ? const Color(0xFF1A2832) : const Color(0xFFE2E8F0);
    final highlight =
        isDark ? const Color(0xFF1E3040) : const Color(0xFFF1F5F9);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Quick Access Banner ────────────────────────────────────────────────────────

class _QuickBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickBanner({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: gradient.first.withValues(alpha: 0.4),
          ),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    sublabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
