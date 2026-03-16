import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:chipin/shared/widgets/error_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) setState(() => _tabIndex = _tabController.index);
    });
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
        title: const Text(
          'My Matches',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Custom tab bar — border-b border-slate-800
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border(context), width: 1),
              ),
            ),
            child: Row(
              children: [
                _TabItem(
                  label: 'Received',
                  isActive: _tabIndex == 0,
                  onTap: () => _tabController.animateTo(0),
                ),
                _TabItem(
                  label: 'Sent',
                  isActive: _tabIndex == 1,
                  onTap: () => _tabController.animateTo(1),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MatchList(type: MatchListType.received),
                _MatchList(type: MatchListType.sent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom tab item ──────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.only(top: 14, bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab list ─────────────────────────────────────────────────────────────────

enum MatchListType { received, sent }

class _MatchList extends ConsumerWidget {
  final MatchListType type;
  const _MatchList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = type == MatchListType.received
        ? ref.watch(receivedMatchesProvider)
        : ref.watch(sentMatchesProvider);

    return matchesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
      error: (e, _) => ErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(
          type == MatchListType.received
              ? receivedMatchesProvider
              : sentMatchesProvider,
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  size: 52,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  type == MatchListType.received
                      ? 'No match requests received yet.'
                      : 'You haven\'t sent any match requests.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(type == MatchListType.received
                ? receivedMatchesProvider
                : sentMatchesProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: matches.length,
            separatorBuilder: (_, i) => Divider(
              height: 1,
              color: AppColors.border(context),
            ),
            itemBuilder: (context, i) => _MatchCard(
              match: matches[i],
              type: type,
            ),
          ),
        );
      },
    );
  }
}

// ── Match card ───────────────────────────────────────────────────────────────

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  final MatchListType type;

  const _MatchCard({required this.match, required this.type});

  bool get _isDimmed =>
      match.status == MatchStatus.expired ||
      match.status == MatchStatus.declined ||
      match.status == MatchStatus.completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherName = type == MatchListType.received
        ? match.requesterName
        : match.ownerName;

    // Message preview text
    final previewText = match.message?.isNotEmpty == true
        ? '"${match.message}"'
        : 'Tap to start chatting';
    final previewItalic = match.message?.isNotEmpty == true;

    Widget card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: thumbnail + info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(match: match),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            match.listingTitle ?? 'Listing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.isDark(context)
                                  ? AppColors.textDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: match.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Username
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          otherName ?? 'Unknown',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message preview
                    Text(
                      previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontStyle: previewItalic
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: previewItalic
                            ? AppColors.textSubtle
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action buttons (hidden for terminal states)
          if (!_isDimmed) ...[
            const SizedBox(height: 16),
            _ActionRow(match: match, type: type),
          ],
        ],
      ),
    );

    if (_isDimmed) {
      card = Opacity(opacity: 0.6, child: card);
    }

    return card;
  }
}

// ── Thumbnail with price badge ────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final MatchModel match;
  const _Thumbnail({required this.match});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(10),
            image: match.listingImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(match.listingImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: match.listingImageUrl == null
              ? const Icon(
                  Icons.handshake_rounded,
                  color: AppColors.primary,
                  size: 30,
                )
              : null,
        ),
        if (match.listingAmount != null)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? AppColors.backgroundDark
                      : AppColors.surfaceLight,
                  width: 2,
                ),
              ),
              child: Text(
                '₦${_fmt(match.listingAmount!)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    }
    return v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(0);
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (status) {
      case MatchStatus.pending:
        textColor = AppColors.statusPending;
        bgColor = AppColors.statusPendingBg;
        borderColor = AppColors.statusPending.withValues(alpha: 0.2);
        break;
      case MatchStatus.accepted:
      case MatchStatus.active:
        textColor = AppColors.statusActive;
        bgColor = AppColors.statusActiveBg;
        borderColor = AppColors.statusActive.withValues(alpha: 0.2);
        break;
      case MatchStatus.expired:
      case MatchStatus.declined:
      case MatchStatus.completed:
        textColor = AppColors.textMuted;
        bgColor = AppColors.surface(context);
        borderColor = AppColors.border(context);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends ConsumerWidget {
  final MatchModel match;
  final MatchListType type;
  const _ActionRow({required this.match, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Received + Pending → Accept Match + Chat icon
    if (type == MatchListType.received && match.status == MatchStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: _FilledBtn(
              label: 'Accept Match',
              bgColor: AppColors.primary,
              textColor: Colors.white,
              onTap: () async {
                await ref
                    .read(matchNotifierProvider.notifier)
                    .acceptMatch(match.id);
                ref.invalidate(receivedMatchesProvider);
              },
            ),
          ),
          const SizedBox(width: 8),
          _ChatIconBtn(
            bgColor: AppColors.surface(context),
            iconColor: AppColors.textSubtle,
            onTap: () => context.push('/chat/${match.id}'),
          ),
        ],
      );
    }

    // Sent + Accepted → Pay Now + Chat icon
    if (type == MatchListType.sent && match.status == MatchStatus.accepted) {
      return Row(
        children: [
          Expanded(
            child: _FilledBtn(
              label: 'Pay Now',
              bgColor: AppColors.primary,
              textColor: Colors.white,
              onTap: () => context.push('/pay/${match.id}'),
            ),
          ),
          const SizedBox(width: 8),
          _ChatIconBtn(
            bgColor: AppColors.primary.withValues(alpha: 0.2),
            iconColor: AppColors.primary,
            onTap: () => context.push('/chat/${match.id}'),
          ),
        ],
      );
    }

    // Received + Accepted / Active (both sides) → Open Chat + Chat icon
    if (match.status == MatchStatus.accepted ||
        match.status == MatchStatus.active) {
      return Row(
        children: [
          Expanded(
            child: _FilledBtn(
              label: 'Open Chat',
              bgColor: AppColors.primary.withValues(alpha: 0.1),
              textColor: AppColors.primary,
              onTap: () => context.push('/chat/${match.id}'),
            ),
          ),
          const SizedBox(width: 8),
          _ChatIconBtn(
            bgColor: AppColors.primary.withValues(alpha: 0.2),
            iconColor: AppColors.primary,
            onTap: () => context.push('/chat/${match.id}'),
          ),
        ],
      );
    }

    // Sent + Pending → View Details + Chat icon
    if (type == MatchListType.sent && match.status == MatchStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: _FilledBtn(
              label: 'View Details',
              bgColor: AppColors.surface(context),
              textColor: AppColors.isDark(context)
                  ? AppColors.textDark
                  : AppColors.textPrimary,
              onTap: () => context.push('/listing/${match.listingId}'),
            ),
          ),
          const SizedBox(width: 8),
          _ChatIconBtn(
            bgColor: AppColors.surface(context),
            iconColor: AppColors.textSubtle,
            onTap: () => context.push('/chat/${match.id}'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Button widgets ────────────────────────────────────────────────────────────

class _FilledBtn extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _FilledBtn({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ChatIconBtn extends StatelessWidget {
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ChatIconBtn({
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}
