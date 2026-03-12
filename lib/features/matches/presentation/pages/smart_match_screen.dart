import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class SmartMatchScreen extends ConsumerWidget {
  const SmartMatchScreen({super.key});

  // Deterministic match score: high fill rate + trusted poster + fresh listing → higher %
  int _matchScore(ListingModel l) {
    final fillRate = l.slotsTotal > 0 ? l.slotsFilled / l.slotsTotal : 0.0;
    final trustBonus = ((l.posterTrustScore ?? 50) / 100) * 15;
    final ageMs = DateTime.now().difference(l.createdAt).inMilliseconds;
    final recency = 1.0 - (ageMs / (30 * 24 * 60 * 60 * 1000)).clamp(0.0, 1.0);
    return (70 + (1 - fillRate) * 15 + trustBonus * 0.5 + recency * 10).round().clamp(70, 99);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('Smart Match'),
          ],
        ),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (all) {
          // Sort by match score descending, take top 10
          final sorted = [...all]
            ..sort((a, b) => _matchScore(b).compareTo(_matchScore(a)));
          final listings = sorted.take(10).toList();

          return CustomScrollView(
            slivers: [
              // Intro section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why these fits',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Based on listing recency, slot availability, and poster trust score — these splits are your best opportunities right now.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (listings.isEmpty)
                SliverFillRemaining(
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
                        const Text(
                          'No recommendations yet.\nCheck back once more splits are posted!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _SmartCard(
                          listing: listings[i],
                          score: _matchScore(listings[i]),
                          isDark: isDark,
                        ),
                      ),
                      childCount: listings.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SmartCard extends StatelessWidget {
  final ListingModel listing;
  final int score;
  final bool isDark;

  const _SmartCard({
    required this.listing,
    required this.score,
    required this.isDark,
  });

  Color get _cardBg => isDark ? AppColors.cardDark : Colors.white;
  Color get _borderColor => isDark
      ? AppColors.primary.withValues(alpha: 0.18)
      : AppColors.borderLight;

  String get _reasonLabel {
    if (listing.slotsLeft == 1) return 'Last spot available';
    if ((listing.posterTrustScore ?? 0) >= 80) return 'Highly trusted poster';
    if (DateTime.now().difference(listing.createdAt).inDays < 3) {
      return 'Just posted';
    }
    return 'Great match for you';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image / category color ──────────────────────────────
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _categoryBg,
                    image: listing.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(listing.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: listing.imageUrl == null
                      ? Center(
                          child: Icon(_categoryIcon,
                              size: 52,
                              color: _categoryColor.withValues(alpha: 0.4)),
                        )
                      : null,
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Match badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '$score% MATCH',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                // Category badge (bottom right)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.category.label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Reason tag
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _reasonLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  if (listing.description != null) ...[
                    Text(
                      listing.description!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Bottom row
                  Row(
                    children: [
                      // Price + slots
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₦${listing.splitAmount.toStringAsFixed(listing.splitAmount.truncateToDouble() == listing.splitAmount ? 0 : 2)}/person',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${listing.slotsLeft} slot${listing.slotsLeft == 1 ? '' : 's'} left • ${timeago.format(listing.createdAt)}',
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
                      // CTA
                      ElevatedButton(
                        onPressed: () => context.push('/listing/${listing.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('View Match'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _categoryBg {
    switch (listing.category) {
      case ListingCategory.apartment:
        return const Color(0xFF1A3A5C);
      case ListingCategory.subscription:
        return const Color(0xFF2D1B4E);
      case ListingCategory.carpool:
        return const Color(0xFF1A3B2E);
      case ListingCategory.bills:
        return const Color(0xFF3B2A1A);
      case ListingCategory.office:
        return const Color(0xFF1A2E3B);
      case ListingCategory.groceries:
        return const Color(0xFF1E3A2F);
      case ListingCategory.other:
        return const Color(0xFF2A2A3B);
    }
  }

  Color get _categoryColor {
    switch (listing.category) {
      case ListingCategory.apartment:
        return const Color(0xFF4A9EE8);
      case ListingCategory.subscription:
        return const Color(0xFFA855F7);
      case ListingCategory.carpool:
        return const Color(0xFF22C55E);
      case ListingCategory.bills:
        return const Color(0xFFF97316);
      case ListingCategory.office:
        return const Color(0xFF14B8A6);
      case ListingCategory.groceries:
        return const Color(0xFF84CC16);
      case ListingCategory.other:
        return const Color(0xFF94A3B8);
    }
  }

  IconData get _categoryIcon {
    switch (listing.category) {
      case ListingCategory.apartment:
        return Icons.apartment_rounded;
      case ListingCategory.subscription:
        return Icons.subscriptions_rounded;
      case ListingCategory.carpool:
        return Icons.directions_car_rounded;
      case ListingCategory.bills:
        return Icons.receipt_long_rounded;
      case ListingCategory.office:
        return Icons.work_rounded;
      case ListingCategory.groceries:
        return Icons.local_grocery_store_rounded;
      case ListingCategory.other:
        return Icons.grid_view_rounded;
    }
  }
}
