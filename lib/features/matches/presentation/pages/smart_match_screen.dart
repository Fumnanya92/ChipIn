import 'dart:ui';

import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

// ── Scoring algorithm (preserved) ────────────────────────────────────────────
int _computeMatchScore(ListingModel l) {
  final fillRate = l.slotsTotal > 0 ? l.slotsFilled / l.slotsTotal : 0.0;
  final trustBonus = ((l.posterTrustScore ?? 50) / 100) * 15;
  final ageMs = DateTime.now().difference(l.createdAt).inMilliseconds;
  final recency =
      1.0 - (ageMs / (30 * 24 * 60 * 60 * 1000)).clamp(0.0, 1.0);
  return (70 + (1 - fillRate) * 15 + trustBonus * 0.5 + recency * 10)
      .round()
      .clamp(70, 99);
}

String _computeReason(ListingModel l) {
  if (l.slotsLeft == 1) return 'Last spot available';
  if ((l.posterTrustScore ?? 0) >= 80) return 'Highly trusted poster';
  if (DateTime.now().difference(l.createdAt).inDays < 3) return 'Just posted';
  return 'Great match for you';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SmartMatchScreen extends ConsumerWidget {
  const SmartMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Smart Match'),
          ],
        ),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (all) {
          // Sort by match score descending, take top 10
          final sorted = [...all]
            ..sort((a, b) =>
                _computeMatchScore(b).compareTo(_computeMatchScore(a)));
          final listings = sorted.take(10).toList();

          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Building your recommendations…',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSubtle
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check back once more splits are posted!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final topCards = listings.take(3).toList();
          final compactCards = listings.skip(3).toList();

          return CustomScrollView(
            slivers: [
              // ── "Why these fits" section ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why these fits',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Matched based on your activity, trust score, and similar users\' splits',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.textMuted
                                      : AppColors.textSecondary,
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

              // ── Full glass cards (top 3) ─────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _FullGlassCard(
                        listing: topCards[i],
                        score: _computeMatchScore(topCards[i]),
                        isDark: isDark,
                      ),
                    ),
                    childCount: topCards.length,
                  ),
                ),
              ),

              // ── Compact cards (lower ranked) ─────────────────────────────
              if (compactCards.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'More Matches',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSubtle
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CompactGlassCard(
                          listing: compactCards[i],
                          score: _computeMatchScore(compactCards[i]),
                          isDark: isDark,
                        ),
                      ),
                      childCount: compactCards.length,
                    ),
                  ),
                ),
              ] else
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

// ── Full Glass Card ───────────────────────────────────────────────────────────

class _FullGlassCard extends StatelessWidget {
  final ListingModel listing;
  final int score;
  final bool isDark;

  const _FullGlassCard({
    required this.listing,
    required this.score,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x0D11B4D4), // primary/5
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x2611B4D4), // primary/15
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ───────────────────────────────────────────
                _HeroImageArea(listing: listing, score: score),

                // ── Card body ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Similar to: reason" row
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Similar to: ${_computeReason(listing)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (listing.description != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          listing.description!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Amount row
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '₦${listing.splitAmount.toStringAsFixed(listing.splitAmount.truncateToDouble() == listing.splitAmount ? 0 : 2)}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text: '/person',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· ${listing.slotsLeft} slot${listing.slotsLeft == 1 ? '' : 's'} left · ${timeago.format(listing.createdAt)}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action buttons row
                      Row(
                        children: [
                          // View Match
                          GestureDetector(
                            onTap: () =>
                                context.push('/listing/${listing.id}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Match',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Quick Join
                          GestureDetector(
                            onTap: () =>
                                context.push('/listing/${listing.id}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Quick Join',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Image Area ───────────────────────────────────────────────────────────

class _HeroImageArea extends StatelessWidget {
  final ListingModel listing;
  final int score;

  const _HeroImageArea({required this.listing, required this.score});

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background / image
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
              ? Container(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  child: Center(
                    child: Icon(
                      _categoryIcon,
                      size: 52,
                      color: _categoryColor.withValues(alpha: 0.4),
                    ),
                  ),
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
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),

        // Match % badge — top-left
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Text(
              '$score% MATCH',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.backgroundDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Compact Glass Card ────────────────────────────────────────────────────────

class _CompactGlassCard extends StatelessWidget {
  final ListingModel listing;
  final int score;
  final bool isDark;

  const _CompactGlassCard({
    required this.listing,
    required this.score,
    required this.isDark,
  });

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x1A11B4D4), // primary/10
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0x3311B4D4), // primary/20
              ),
            ),
            child: Row(
              children: [
                // Category icon square
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _categoryIcon,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Small match badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$score%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (listing.description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          listing.description!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${listing.slotsLeft} slot${listing.slotsLeft == 1 ? '' : 's'} left',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '₦${listing.splitAmount.toStringAsFixed(listing.splitAmount.truncateToDouble() == listing.splitAmount ? 0 : 2)}/person',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSubtle
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
