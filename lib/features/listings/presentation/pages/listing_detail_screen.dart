import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _isRequesting = false;
  bool _hasRequested = false;

  Future<void> _requestToJoin(ListingModel listing) async {
    setState(() => _isRequesting = true);
    try {
      await ref.read(matchNotifierProvider.notifier).requestToJoin(
            listing.id,
            listing.userId,
          );
      if (!mounted) return;
      setState(() => _hasRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! The owner will get back to you.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingByIdProvider(widget.listingId));
    final currentUserId = ref.read(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: listingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load listing: $e'),
        ),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('Listing not found.'));
          }
          final slotsLeft = listing.slotsLeft;

          return CustomScrollView(
            slivers: [
              // ── Image / Hero header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.surfaceLight,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: listing.imageUrl != null
                      ? Image.network(listing.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: _categoryBg(listing.category),
                          child: Center(
                            child: Icon(
                              _categoryIcon(listing.category),
                              size: 80,
                              color: _categoryColor(listing.category)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge + title
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryColor(listing.category),
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
                      const SizedBox(height: 10),
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.public_rounded,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            listing.isRemote ? 'Remote / Global' : listing.location,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Poster row
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
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
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        listing.posterName ?? 'Unknown',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded,
                                          size: 14, color: AppColors.primary),
                                    ],
                                  ),
                                  if (listing.posterTrustScore != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 13, color: AppColors.warning),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Trust Score: ${listing.posterTrustScore!.toInt()}%',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/profile/${listing.userId}'),
                              child: const Text('View Profile',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cost cards
                      Row(
                        children: [
                          Expanded(
                            child: _CostCard(
                              label: 'Total Plan',
                              value:
                                  '\$${listing.totalCost.toStringAsFixed(listing.totalCost.truncateToDouble() == listing.totalCost ? 0 : 2)}',
                              suffix: _durationSuffix(listing.duration),
                              icon: Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CostCard(
                              label: 'Your Share',
                              value:
                                  '\$${listing.splitAmount.toStringAsFixed(listing.splitAmount.truncateToDouble() == listing.splitAmount ? 0 : 2)}',
                              suffix: _durationSuffix(listing.duration),
                              icon: Icons.person_outlined,
                              highlight: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Availability
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.group_rounded,
                                size: 20,
                                color: slotsLeft > 0
                                    ? AppColors.success
                                    : AppColors.error),
                            const SizedBox(width: 10),
                            Text(
                              'Availability',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$slotsLeft/${listing.slotsTotal} Slots Left',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: slotsLeft > 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // About
                      if (listing.description?.isNotEmpty == true) ...[
                        const Text(
                          'About this split',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          listing.description!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tags
                      if (listing.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: listing.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Features
                      _FeatureRow(
                        icon: Icons.check_circle_outline_rounded,
                        text: listing.duration == ListingDuration.monthly
                            ? 'Auto-Renew enabled — payments every 30 days'
                            : 'One-time payment',
                      ),
                      const SizedBox(height: 8),
                      _FeatureRow(
                        icon: Icons.check_circle_outline_rounded,
                        text: listing.isRemote
                            ? 'Remote / Global — no location required'
                            : 'Location: ${listing.location}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ── Sticky bottom CTA ──────────────────────────────────────────────
      bottomNavigationBar: listingAsync.maybeWhen(
        data: (listing) {
          if (listing == null) return null;
          final isOwner = listing.userId == currentUserId;
          final slotsLeft = listing.slotsLeft;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: ElevatedButton(
                onPressed: isOwner || _hasRequested || slotsLeft == 0 || _isRequesting
                    ? null
                    : () => _requestToJoin(listing),
                child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isOwner
                                ? 'Your Listing'
                                : _hasRequested
                                    ? 'Request Sent ✓'
                                    : slotsLeft == 0
                                        ? 'No Slots Available'
                                        : 'Request to Join',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (!isOwner && !_hasRequested && slotsLeft > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  String _durationSuffix(ListingDuration d) {
    switch (d) {
      case ListingDuration.monthly:
        return '/mo';
      case ListingDuration.oneTime:
        return '';
      case ListingDuration.custom:
        return '/pp';
    }
  }

  Color _categoryColor(ListingCategory c) {
    switch (c) {
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

  Color _categoryBg(ListingCategory c) {
    switch (c) {
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

  IconData _categoryIcon(ListingCategory c) {
    switch (c) {
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

class _CostCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final bool highlight;

  const _CostCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: highlight ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: highlight ? Colors.white : AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: highlight
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
