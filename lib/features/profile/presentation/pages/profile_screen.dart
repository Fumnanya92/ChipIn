import 'package:cached_network_image/cached_network_image.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/features/profile/presentation/providers/profile_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:chipin/shared/models/review_model.dart';
import 'package:chipin/shared/models/user_model.dart';
import 'package:chipin/shared/widgets/error_retry.dart';
import 'package:chipin/main.dart' show themeModeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final userReviewsProvider =
    FutureProvider.autoDispose.family<List<ReviewModel>, String>((ref, userId) async {
  final supabase = ref.read(supabaseClientProvider);
  final data = await supabase
      .from('reviews')
      .select('*, reviewer:reviewer_id(full_name, avatar_url)')
      .eq('reviewee_id', userId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

final userActiveSplitsProvider =
    FutureProvider.autoDispose.family<List<ListingModel>, String>((ref, userId) async {
  final supabase = ref.read(supabaseClientProvider);
  final data = await supabase
      .from('listings')
      .select()
      .eq('user_id', userId)
      .eq('status', 'active')
      .order('created_at', ascending: false)
      .limit(5);
  return (data as List)
      .map((d) => ListingModel.fromJson(d as Map<String, dynamic>))
      .toList();
});

// ── ProfileScreen ──────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUserId = ref.read(currentUserIdProvider);
    final isMyProfile = userId == 'me' || userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isMyProfile,
        title: const Text('Profile'),
        actions: [
          if (isMyProfile) ...[
            _ThemeToggleButton(),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(authNotifierProvider),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 52, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'Profile not found.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isMyProfile) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ],
              ),
            );
          }
          return _ProfileBody(user: user, isMyProfile: isMyProfile, ref: ref);
        },
      ),
    );
  }
}

// ── _ProfileBody ───────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserModel user;
  final bool isMyProfile;
  final WidgetRef ref;

  const _ProfileBody({
    required this.user,
    required this.isMyProfile,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textDarkColor = isDark ? AppColors.textDark : AppColors.textPrimary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        const SizedBox(height: 24),

        // ── Avatar ────────────────────────────────────────────────────
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          cacheKey: user.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _AvatarFallback(name: user.displayName),
                        )
                      : _AvatarFallback(name: user.displayName),
                ),
              ),
              if (user.idVerified)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Name ──────────────────────────────────────────────────────
        Center(
          child: Text(
            user.displayName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textDarkColor,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // ── Member since + location ───────────────────────────────────
        Center(
          child: Text(
            [
              'Member since ${DateFormat('MMM yyyy').format(user.createdAt)}',
              if (user.location?.isNotEmpty == true) user.location!,
            ].join(' \u2022 '),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Bio ───────────────────────────────────────────────────────
        if (user.bio?.isNotEmpty == true) ...[
          Center(
            child: Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? AppColors.textSubtle : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Edit Profile button (own profile) — compact, centered ─────
        if (isMyProfile) ...[
          Center(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () => context.push('/me/edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 8),

        // ── Stats Cards — Trust Score + Rating ────────────────────────
        Row(
          children: [
            // Trust Score card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1A11B4D4), // primary/10
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x3311B4D4), // primary/20
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'TRUST SCORE',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.trustScore.toInt()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: textDarkColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Rating card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSlate.withValues(alpha: 0.5)
                        : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'RATING',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: textDarkColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Verification Badges ────────────────────────────────────────
        Text(
          'Verification Badges',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textDarkColor,
          ),
        ),
        const SizedBox(height: 12),
        if (!user.phoneVerified && !user.idVerified && !user.paymentVerified)
          Text(
            'No verifications yet.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user.phoneVerified)
                const _VerifiedBadge(label: 'Phone Verified'),
              if (user.idVerified)
                const _VerifiedBadge(label: 'ID Verified'),
              if (user.paymentVerified)
                const _VerifiedBadge(label: 'Payment Verified'),
            ],
          ),
        const SizedBox(height: 20),

        // ── Improve Trust Score (own profile, not fully verified) ──────
        if (isMyProfile && !(user.idVerified && user.paymentVerified)) ...[
          OutlinedButton.icon(
            onPressed: () => context.push('/verify'),
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            label: const Text('Improve Trust Score'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),

        // ── Active Splits ──────────────────────────────────────────────
        _ActiveSplitsSection(userId: user.id, isMyProfile: isMyProfile),
        const SizedBox(height: 28),

        // ── Past Reviews ───────────────────────────────────────────────
        _ReviewsSection(userId: user.id),
        const SizedBox(height: 28),

        // ── Sign Out button (own profile) ──────────────────────────────
        if (isMyProfile)
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
      ],
    );
  }
}

// ── _AvatarFallback ────────────────────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── _VerifiedBadge ─────────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  final String label;
  const _VerifiedBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.verifiedBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.verifiedBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.verifiedGreen,
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.verifiedGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ActiveSplitsSection ───────────────────────────────────────────────────────

class _ActiveSplitsSection extends ConsumerWidget {
  final String userId;
  final bool isMyProfile;
  const _ActiveSplitsSection({required this.userId, this.isMyProfile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitsAsync = ref.watch(userActiveSplitsProvider(userId));
    final isDark = AppColors.isDark(context);
    final textDarkColor = isDark ? AppColors.textDark : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Splits',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textDarkColor,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/browse'),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        splitsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            'Could not load splits',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          data: (splits) {
            if (splits.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.5)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSlate.withValues(alpha: 0.5)
                        : AppColors.borderLight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No active splits yet.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: splits
                  .map((split) => _SplitRow(split: split, isMyProfile: isMyProfile))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── _SplitRow ─────────────────────────────────────────────────────────────────

class _SplitRow extends ConsumerWidget {
  final ListingModel split;
  final bool isMyProfile;
  const _SplitRow({required this.split, this.isMyProfile = false});

  IconData get _categoryIcon {
    switch (split.category) {
      case ListingCategory.apartment:
        return Icons.apartment_rounded;
      case ListingCategory.subscription:
        return Icons.subscriptions_rounded;
      case ListingCategory.carpool:
        return Icons.directions_car_rounded;
      case ListingCategory.bills:
        return Icons.receipt_long_rounded;
      case ListingCategory.office:
        return Icons.business_rounded;
      case ListingCategory.groceries:
        return Icons.local_grocery_store_rounded;
      case ListingCategory.other:
        return Icons.category_rounded;
    }
  }

  void _showManageSheet(BuildContext context, WidgetRef ref) {
    final isActive = split.status == ListingStatus.active;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Listing'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/listing/${split.id}');
              },
            ),
            ListTile(
              leading: Icon(
                isActive
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                color: AppColors.primary,
              ),
              title: Text(isActive ? 'Mark as Inactive' : 'Reactivate'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                try {
                  await ref
                      .read(listingsNotifierProvider.notifier)
                      .updateListingStatus(
                        split.id,
                        isActive ? 'paused' : 'active',
                      );
                  ref.invalidate(userActiveSplitsProvider(split.userId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: const Text(
                'Delete Listing',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to delete this listing? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(listingsNotifierProvider.notifier)
                    .deleteListing(split.id);
                ref.invalidate(userActiveSplitsProvider(split.userId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final textDarkColor = isDark ? AppColors.textDark : AppColors.textPrimary;
    final amountText =
        '\u20A6${NumberFormat('#,##0').format(split.splitAmount)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.5)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.borderSlate.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Category icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x1A11B4D4), // primary/10
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  split.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDarkColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${split.category.label} \u2022 '
                  '${split.slotsTotal} member${split.slotsTotal == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDarkColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                split.status.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: split.status == ListingStatus.active
                      ? AppColors.primary
                      : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          // 3-dot manage button (own profile only)
          if (isMyProfile) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              onPressed: () => _showManageSheet(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _ReviewsSection ────────────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  final String userId;
  const _ReviewsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider(userId));
    final isDark = AppColors.isDark(context);
    final textDarkColor = isDark ? AppColors.textDark : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Past Reviews',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textDarkColor,
              ),
            ),
            reviewsAsync.maybeWhen(
              data: (reviews) => reviews.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            'Could not load reviews: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Text(
                'No reviews yet. Complete a split to receive your first review!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
              );
            }
            return Column(
              children: reviews.asMap().entries.map((entry) {
                return _ReviewCard(
                  review: entry.value,
                  isLast: entry.key == reviews.length - 1,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── _ReviewCard ────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isLast;

  const _ReviewCard({required this.review, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textDarkColor = isDark ? AppColors.textDark : AppColors.textPrimary;
    final emptyStarColor = isDark ? AppColors.borderSlate : AppColors.borderLight;

    return Container(
      padding: EdgeInsets.only(
        top: 0,
        bottom: isLast ? 0 : 16,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars + reviewer name
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < review.rating
                        ? AppColors.starColor
                        : emptyStarColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName ?? 'Anonymous',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textDarkColor,
                  ),
                ),
              ),
            ],
          ),
          // Comment
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              '"${review.comment!}"',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? AppColors.textSubtle : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          // Date
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(review.createdAt).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          if (!isLast) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── _ThemeToggleButton ─────────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      onPressed: () {
        ref.read(themeModeProvider.notifier).state =
            isDark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
