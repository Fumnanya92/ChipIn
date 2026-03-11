import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
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

  static const _categories = [
    _Category('subscription', 'Subs', Icons.subscriptions_rounded, AppColors.catSubscription, AppColors.catSubscriptionBg),
    _Category('apartment', 'Housing', Icons.home_rounded, AppColors.catHousing, AppColors.catHousingBg),
    _Category('carpool', 'Travel', Icons.flight_rounded, AppColors.catTravel, AppColors.catTravelBg),
    _Category('groceries', 'Groceries', Icons.shopping_cart_rounded, AppColors.catGroceries, AppColors.catGroceriesBg),
    _Category('office', 'Work', Icons.desktop_windows_rounded, AppColors.catWork, AppColors.catWorkBg),
    _Category('bills', 'Bills', Icons.receipt_long_rounded, AppColors.catBills, AppColors.catBills),
  ];

  @override
  Widget build(BuildContext context) {
    final listingsAsync = _selectedCategory == null
        ? ref.watch(listingsProvider)
        : ref.watch(listingsByCategoryProvider(_selectedCategory));
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/me'),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!)
                            : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                (user?.displayName.isNotEmpty == true)
                                    ? user!.displayName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'ChipIn',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            size: 22, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => context.go('/browse'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Search splits…',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Categories ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                child: Row(
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = null);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat.key;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _selectedCategory = selected ? null : cat.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : cat.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 20,
                                color: selected ? Colors.white : cat.color),
                            const SizedBox(height: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
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

            // ── Featured Splits header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Featured Splits',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.tune_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            // ── Listings ──────────────────────────────────────────────────
            listingsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ShimmerCard(),
                  childCount: 4,
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('Could not load listings.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
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
                          const Text('No splits found',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          const Text('Be the first to post a split!',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
    );
  }
}

// ── Category data ──────────────────────────────────────────────────────────────

class _Category {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _Category(this.key, this.label, this.icon, this.color, this.bgColor);
}

// ── Listing Card ──────────────────────────────────────────────────────────────

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

  Color get _categoryBg {
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
        return AppColors.catBills.withValues(alpha: 0.1);
      case ListingCategory.other:
        return AppColors.catOtherBg;
    }
  }

  String get _priceLabel {
    final amount = listing.splitAmount;
    switch (listing.duration) {
      case ListingDuration.monthly:
        return '\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}/mo';
      case ListingDuration.oneTime:
        return '\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
      case ListingDuration.custom:
        return '\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}/pp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotsLeft = listing.slotsLeft;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card hero / image area
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _categoryBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                image: listing.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(listing.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                  // Price badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
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
                  ),
                  // Category icon if no image
                  if (listing.imageUrl == null)
                    Center(
                      child: Icon(
                        _categoryIconData(),
                        size: 48,
                        color: _categoryColor.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),

            // ── Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Poster avatar
                      CircleAvatar(
                        radius: 14,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.posterName ?? 'Unknown',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (listing.posterTrustScore != null)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: AppColors.warning),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Trust Score: ${listing.posterTrustScore!.toInt()}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Slots chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: slotsLeft > 0
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Slots Left $slotsLeft/${listing.slotsTotal}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: slotsLeft > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: slotsLeft > 0 ? onTap : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        slotsLeft > 0 ? 'Request to Join' : 'Full',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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

  IconData _categoryIconData() {
    switch (listing.category) {
      case ListingCategory.subscription:
        return Icons.subscriptions_rounded;
      case ListingCategory.apartment:
        return Icons.home_rounded;
      case ListingCategory.carpool:
        return Icons.directions_car_rounded;
      case ListingCategory.groceries:
        return Icons.shopping_cart_rounded;
      case ListingCategory.office:
        return Icons.desktop_windows_rounded;
      case ListingCategory.bills:
        return Icons.receipt_long_rounded;
      case ListingCategory.other:
        return Icons.category_rounded;
    }
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}