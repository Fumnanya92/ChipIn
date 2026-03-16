import 'package:cached_network_image/cached_network_image.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/messages/presentation/providers/messages_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:chipin/shared/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Fetches full match details (both users) for the chat AppBar / banner.
final _matchDetailProvider =
    FutureProvider.autoDispose.family<MatchModel?, String>((ref, matchId) async {
  final supabase = ref.read(supabaseClientProvider);
  final data = await supabase
      .from('matches')
      .select(
        '*, '
        'listings(title, image_url, split_amount), '
        'requester:users!matches_requester_id_fkey(full_name, avatar_url, trust_score), '
        'owner:users!matches_owner_id_fkey(full_name, avatar_url, trust_score)',
      )
      .eq('id', matchId)
      .maybeSingle();
  if (data == null) return null;
  return MatchModel.fromJson(data);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when screen opens
    Future.microtask(() =>
        ref.read(messagesNotifierProvider.notifier).markRead(widget.matchId));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _msgCtrl.clear();
    try {
      await ref
          .read(messagesNotifierProvider.notifier)
          .sendMessage(widget.matchId, text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.matchId));
    final matchAsync = ref.watch(_matchDetailProvider(widget.matchId));
    final currentUserId = ref.read(currentUserIdProvider);

    final match = matchAsync.valueOrNull;
    final isOwner = match?.ownerId == currentUserId;

    // Determine the "other" user
    final otherName =
        isOwner ? match?.requesterName : match?.ownerName;
    final otherAvatar =
        isOwner ? match?.requesterAvatarUrl : match?.ownerAvatarUrl;
    final otherTrustScore = isOwner
        ? match?.requesterTrustScore
        : null; // ownerTrustScore not in model — fallback below

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMuted),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar with green online dot
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    color: AppColors.surface(context),
                    image: otherAvatar != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              otherAvatar,
                              cacheKey: otherAvatar,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: otherAvatar == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22C55E), // green-500
                      border: Border.all(
                        color: AppColors.surface(context),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Name + trust score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherName ?? 'Match Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOn(context),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        otherTrustScore != null
                            ? 'Trust Score: ${otherTrustScore.toInt()}%'
                            : 'Trust Verified',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Confirm / escrow banner ───────────────────────────────────────
          _ConfirmBanner(
            match: match,
            onConfirm: () => context.push('/pay/${widget.matchId}'),
          ),

          // ── Messages list ─────────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Could not load messages: $e',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello to get the split started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    // Descending order (newest at index 0, oldest at last).
                    // Show date divider above the topmost message of each day:
                    // the very oldest message always gets one; otherwise show
                    // one when the next-older neighbour (i+1) is a different day.
                    final showDate = i == messages.length - 1 ||
                        !_sameDay(messages[i + 1].createdAt, msg.createdAt);
                    // Show escrow prompt once in the middle of conversation
                    final showEscrow = i == (messages.length / 2).floor() &&
                        messages.length >= 3;

                    return Column(
                      children: [
                        if (showDate) _DateDivider(msg.createdAt),
                        _MessageBubble(message: msg, isMe: isMe),
                        if (showEscrow) const _EscrowPrompt(),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Quick action chips ────────────────────────────────────────────
          Container(
            color: AppColors.scaffoldBg(context),
            child: SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                children: [
                  _QuickChip(
                    label: 'Request Escrow',
                    icon: Icons.payments_outlined,
                    onTap: () => context.push('/pay/${widget.matchId}'),
                  ),
                  const SizedBox(width: 8),
                  _QuickChip(
                    label: 'Send Receipt',
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _msgCtrl.text = 'Here\'s the receipt for our split.',
                  ),
                  const SizedBox(width: 8),
                  _QuickChip(
                    label: 'Reminder',
                    icon: Icons.schedule_outlined,
                    onTap: () => _msgCtrl.text =
                        'Just a friendly reminder about our split.',
                  ),
                ],
              ),
            ),
          ),

          // ── Input bar ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              border: Border(
                top: BorderSide(color: AppColors.surface(context)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Plus icon
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 26,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.scaffoldBg(context),
                        // Note icon inside field at trailing end
                        suffixIcon: const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send FAB
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Confirm / escrow banner ──────────────────────────────────────────────────

class _ConfirmBanner extends StatelessWidget {
  final MatchModel? match;
  final VoidCallback onConfirm;
  const _ConfirmBanner({required this.match, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final title = match?.listingTitle != null
        ? match!.listingTitle!
        : 'Split';
    final amount = match?.listingAmount;
    final displayTitle = amount != null
        ? '$title: ₦${_fmt(amount)}'
        : title;

    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          // Title + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOn(context),
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Waiting for agreement',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Confirm Split button
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Confirm Split',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(0);
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user avatar (received)
          if (!isMe) ...[
            _Avatar(
              avatarUrl: message.senderAvatarUrl,
              name: message.senderName,
            ),
            const SizedBox(width: 8),
          ],

          // Bubble + time row
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isMe ? AppColors.primary : AppColors.surface(context),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft:
                            Radius.circular(isMe ? 20 : 2),
                        bottomRight:
                            Radius.circular(isMe ? 2 : 20),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isMe ? Colors.white : AppColors.textOn(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Time + read receipt (outside bubble)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 3),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sender avatar (sent)
          if (isMe) ...[
            const SizedBox(width: 8),
            _Avatar(
              avatarUrl: message.senderAvatarUrl,
              name: message.senderName,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

// ── Small avatar widget ───────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  const _Avatar({this.avatarUrl, this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
        image: avatarUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  avatarUrl!,
                  cacheKey: avatarUrl!,
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: avatarUrl == null
          ? Text(
              name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

// ── Date divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Escrow system message ─────────────────────────────────────────────────────

class _EscrowPrompt extends StatelessWidget {
  const _EscrowPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.borderSlate,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      children: [
                        TextSpan(text: 'Funds are held securely in '),
                        TextSpan(
                          text: 'Escrow',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' until both parties confirm.'),
                      ],
                    ),
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

// Draws a dashed rounded-rect border using CustomPainter.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final BorderRadius borderRadius;

  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  static const double _strokeWidth = 1.0;
  static const double _dashWidth = 6.0;
  static const double _dashSpace = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = borderRadius
        .toRRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + _dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashWidth + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius;
}

// ── Quick action chip ─────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSubtle),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
