import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Smart Match',
            onPressed: () => context.push('/smart-match'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MatchList(type: MatchListType.received),
          _MatchList(type: MatchListType.sent),
        ],
      ),
    );
  }
}

enum MatchListType { received, sent }

class _MatchList extends ConsumerWidget {
  final MatchListType type;
  const _MatchList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = type == MatchListType.received
        ? ref.watch(receivedMatchesProvider)
        : ref.watch(sentMatchesProvider);
    final currentUserId = ref.read(currentUserIdProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined,
                    size: 52, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  type == MatchListType.received
                      ? 'No match requests received yet.'
                      : 'You haven\'t sent any match requests.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(type == MatchListType.received
                ? receivedMatchesProvider
                : sentMatchesProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _MatchCard(
              match: matches[i],
              type: type,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  final MatchListType type;
  final String? currentUserId;

  const _MatchCard(
      {required this.match, required this.type, required this.currentUserId});

  Color _statusColor(MatchStatus s) {
    switch (s) {
      case MatchStatus.pending:
        return AppColors.warning;
      case MatchStatus.accepted:
        return AppColors.success;
      case MatchStatus.active:
        return AppColors.primary;
      case MatchStatus.declined:
      case MatchStatus.expired:
        return AppColors.error;
      case MatchStatus.completed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherName = type == MatchListType.received
        ? match.requesterName
        : match.ownerName;
    final otherAvatar = type == MatchListType.received
        ? match.requesterAvatarUrl
        : match.ownerAvatarUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Listing image / placeholder
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    image: match.listingImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(match.listingImageUrl!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: match.listingImageUrl == null
                      ? const Icon(Icons.handshake_rounded,
                          color: AppColors.primary, size: 26)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.listingTitle ?? 'Listing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (match.listingAmount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${match.listingAmount!.toStringAsFixed(match.listingAmount!.truncateToDouble() == match.listingAmount! ? 0 : 2)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: otherAvatar != null
                                ? NetworkImage(otherAvatar)
                                : null,
                            child: otherAvatar == null
                                ? Text(
                                    otherName?.isNotEmpty == true
                                        ? otherName![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary))
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            otherName ?? 'Unknown',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(match.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              match.status.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(match.status),
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

          // Message snippet
          if (match.message?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                '"${match.message}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Text(
                  timeago.format(match.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (type == MatchListType.received &&
                    match.status == MatchStatus.pending) ...[
                  _ActionButton(
                    label: 'Accept',
                    color: AppColors.success,
                    onTap: () async {
                      await ref
                          .read(matchNotifierProvider.notifier)
                          .acceptMatch(match.id);
                      ref.invalidate(receivedMatchesProvider);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Decline',
                    color: AppColors.error,
                    outline: true,
                    onTap: () async {
                      await ref
                          .read(matchNotifierProvider.notifier)
                          .declineMatch(match.id);
                      ref.invalidate(receivedMatchesProvider);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (match.status == MatchStatus.accepted ||
                    match.status == MatchStatus.active) ...[
                  _ActionButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => context.push('/chat/${match.id}'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: match.status == MatchStatus.active
                        ? 'Escrow'
                        : 'Pay Escrow',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.push(
                        match.status == MatchStatus.active
                            ? '/escrow/${match.id}'
                            : '/pay/${match.id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool outline;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    this.icon,
    this.color = AppColors.primary,
    this.outline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: outline ? color : Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: outline ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
