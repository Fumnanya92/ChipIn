import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesInboxScreen extends ConsumerWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivedAsync = ref.watch(receivedMatchesProvider);
    final sentAsync = ref.watch(sentMatchesProvider);
    final currentUserId = ref.read(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
      ),
      body: receivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (received) => sentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sent) {
            // Combine and filter to only accepted/active chats
            final allMatches = [...received, ...sent];
            final chatMatches = allMatches
                .where((m) =>
                    m.status == MatchStatus.accepted ||
                    m.status == MatchStatus.active)
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            if (chatMatches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active chats yet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Once a match is accepted, you can chat here to plan your split.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/matches'),
                      icon: const Icon(Icons.handshake_rounded),
                      label: const Text('View Matches'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 48),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(receivedMatchesProvider);
                ref.invalidate(sentMatchesProvider);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: chatMatches.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final match = chatMatches[i];
                  final isOwner = match.ownerId == currentUserId;
                  final otherName = isOwner
                      ? match.requesterName
                      : match.ownerName;
                  final otherAvatar = isOwner
                      ? match.requesterAvatarUrl
                      : match.ownerAvatarUrl;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    onTap: () => context.push('/chat/${match.id}'),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: otherAvatar != null
                          ? NetworkImage(otherAvatar)
                          : null,
                      child: otherAvatar == null
                          ? Text(
                              (otherName ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      otherName ?? 'Partner',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      match.listingTitle ?? 'Shared split',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeago.format(match.updatedAt),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: match.status == MatchStatus.active
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.status == MatchStatus.active
                                ? 'Active'
                                : 'Accepted',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: match.status == MatchStatus.active
                                  ? AppColors.primary
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
