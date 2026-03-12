import 'package:chipin/core/config/app_constants.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/shared/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ── Provider ──────────────────────────────────────────────────────────────────

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .from(AppConstants.notificationsTable)
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(60);

  return (rows as List)
      .map((r) => NotificationModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  Future<void> _markAllRead(List<NotificationModel> notifications) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final unreadIds = notifications
        .where((n) => !n.read)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isEmpty) return;

    await Supabase.instance.client
        .from(AppConstants.notificationsTable)
        .update({'read': true})
        .eq('user_id', userId)
        .inFilter('id', unreadIds);

    ref.invalidate(notificationsProvider);
  }

  void _handleTap(BuildContext context, NotificationModel n) {
    final data = n.data ?? {};
    switch (n.type) {
      case NotificationType.matchRequest:
      case NotificationType.matchAccepted:
      case NotificationType.matchDeclined:
        context.push('/matches');
      case NotificationType.newMessage:
        final matchId = data['match_id'] as String?;
        if (matchId != null) context.push('/chat/$matchId');
      case NotificationType.paymentReceived:
      case NotificationType.splitConfirmed:
        final listingId = data['listing_id'] as String?;
        if (listingId != null) context.push('/listing/$listingId');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) => list.any((n) => !n.read)
                ? TextButton(
                    onPressed: () => _markAllRead(list),
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading notifications: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 56,
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You'll be notified here about matches,\nmessages and payments.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(
                notification: n,
                onTap: () => _handleTap(context, n),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile(
      {required this.notification, required this.onTap});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.matchRequest:
        return Icons.person_add_rounded;
      case NotificationType.matchAccepted:
        return Icons.handshake_rounded;
      case NotificationType.matchDeclined:
        return Icons.person_off_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.paymentReceived:
        return Icons.payments_rounded;
      case NotificationType.splitConfirmed:
        return Icons.check_circle_rounded;
      case NotificationType.reviewReceived:
        return Icons.star_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.matchRequest:
      case NotificationType.matchAccepted:
        return AppColors.primary;
      case NotificationType.matchDeclined:
        return AppColors.error;
      case NotificationType.newMessage:
        return AppColors.info;
      case NotificationType.paymentReceived:
      case NotificationType.splitConfirmed:
        return AppColors.success;
      case NotificationType.reviewReceived:
        return AppColors.warning;
      case NotificationType.general:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    final isUnread = !notification.read;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(notification.type),
                  size: 22, color: color),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(notification.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread dot
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
