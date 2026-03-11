import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/profile/presentation/providers/profile_provider.dart';
import 'package:chipin/shared/models/review_model.dart';
import 'package:chipin/shared/models/user_model.dart';
import 'package:chipin/main.dart' show themeModeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Provider for reviews of a given user
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

class ProfileScreen extends ConsumerWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUserId = ref.read(currentUserIdProvider);
    final isMyProfile =
        userId == 'me' || userId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: !isMyProfile,
        title: const Text('Profile'),
        actions: [
          if (isMyProfile) ...[  
            IconButton(
              icon: const Icon(Icons.verified_user_rounded),
              tooltip: 'Verify Identity',
              onPressed: () => context.push('/verify'),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => context.push('/me/edit'),
            ),
            _ThemeToggleButton(),
          ],
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load profile: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
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
                  const Text('Profile not found.',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: AppColors.textSecondary)),
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
          return _ProfileBody(
              user: user, isMyProfile: isMyProfile, ref: ref);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserModel user;
  final bool isMyProfile;
  final WidgetRef ref;

  const _ProfileBody(
      {required this.user,
      required this.isMyProfile,
      required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        const SizedBox(height: 20),

        // ── Avatar + name ──────────────────────────────────────────────
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              if (user.idVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.displayName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            [
              'Member since ${DateFormat('MMM yyyy').format(user.createdAt)}',
              if (user.location?.isNotEmpty == true) user.location!,
            ].join(' · '),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (user.bio?.isNotEmpty == true) ...[
          Center(
            child: Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (isMyProfile)
          OutlinedButton(
            onPressed: () => context.push('/me/edit'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
            child: const Text('Edit Profile'),
          ),
        const SizedBox(height: 20),

        // ── Trust Score + Rating cards ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.shield_rounded,
                iconColor: AppColors.primary,
                label: 'Trust Score',
                value: '${user.trustScore.toInt()}',
                subtitle: 'out of 100',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                iconColor: AppColors.warning,
                label: 'Rating',
                value: user.averageRating.toStringAsFixed(1),
                subtitle: '${user.totalSplits} split${user.totalSplits == 1 ? '' : 's'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Verification Badges ────────────────────────────────────────
        const Text(
          'Verification Badges',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _BadgeRow(
                icon: Icons.phone_rounded,
                label: 'Phone Verified',
                active: user.phoneVerified,
              ),
              const Divider(height: 20),
              _BadgeRow(
                icon: Icons.badge_rounded,
                label: 'ID Verified',
                active: user.idVerified,
              ),
              const Divider(height: 20),
              _BadgeRow(
                icon: Icons.credit_card_rounded,
                label: 'Payment Verified',
                active: user.paymentVerified,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Verify button (own profile, unverified) ───────────────────
        if (isMyProfile && !(user.idVerified && user.paymentVerified)) ...[  
          OutlinedButton.icon(
            onPressed: () => context.push('/verify'),
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            label: const Text('Improve Trust Score'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
          ),
          const SizedBox(height: 20),
        ],

        // ── Reviews ───────────────────────────────────────────────────
        _ReviewsSection(userId: user.id),
        const SizedBox(height: 20),

        // ── Sign out (only for own profile) ───────────────────────────
        if (isMyProfile) ...[
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
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BadgeRow(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.borderLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.success : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Icon(
          active
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: active ? AppColors.success : AppColors.textMuted,
        ),
      ],
    );
  }
}

// ── Reviews Section ───────────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  final String userId;
  const _ReviewsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Could not load reviews: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Center(
                  child: Text(
                    'No reviews yet. Complete a split to receive your first review!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: reviews
                  .map((r) => _ReviewCard(review: r))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: review.reviewerAvatarUrl != null
                    ? NetworkImage(review.reviewerAvatarUrl!)
                    : null,
                child: review.reviewerAvatarUrl == null
                    ? Text(
                        (review.reviewerName?.isNotEmpty == true)
                            ? review.reviewerName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
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
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
