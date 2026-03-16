import 'package:cached_network_image/cached_network_image.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ManualPaymentScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ManualPaymentScreen({super.key, required this.matchId});

  @override
  ConsumerState<ManualPaymentScreen> createState() =>
      _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends ConsumerState<ManualPaymentScreen> {
  bool _loading = false;
  bool _uploadingReceipt = false;

  Future<void> _markPaid() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(matchNotifierProvider.notifier)
          .markRequesterPaid(widget.matchId);
      ref.invalidate(matchByIdProvider(widget.matchId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(matchNotifierProvider.notifier)
          .confirmPaymentReceived(widget.matchId);
      ref.invalidate(matchByIdProvider(widget.matchId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null) return;

    setState(() => _uploadingReceipt = true);
    try {
      final bytes = await picked.readAsBytes();
      final rawExt = picked.path.split('.').last.toLowerCase();
      final ext =
          ['jpg', 'jpeg', 'png', 'webp'].contains(rawExt) ? rawExt : 'jpg';
      await ref
          .read(matchNotifierProvider.notifier)
          .uploadReceipt(widget.matchId, bytes, ext);
      ref.invalidate(matchByIdProvider(widget.matchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingReceipt = false);
    }
  }

  void _showInstructionsSheet(MatchModel match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentInstructionsSheet(
        matchId: widget.matchId,
        initialInstructions: match.paymentInstructions,
        onSaved: () => ref.invalidate(matchByIdProvider(widget.matchId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: matchAsync.maybeWhen(
          data: (match) => Column(
            children: [
              const Text(
                'Payment',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (match != null)
                Text(
                  match.listingTitle ?? 'Split',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          orElse: () => const Text(
            'Payment',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: matchAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error loading match: $e',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (match) {
          if (match == null) {
            return const Center(
              child: Text(
                'Match not found.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            );
          }
          final isRequester = match.requesterId == currentUserId;
          return _PaymentBody(
            match: match,
            isRequester: isRequester,
            loading: _loading,
            uploadingReceipt: _uploadingReceipt,
            onMarkPaid: _markPaid,
            onConfirmPayment: _confirmPayment,
            onUploadReceipt: _pickAndUploadReceipt,
            onSetInstructions: () => _showInstructionsSheet(match),
          );
        },
      ),
    );
  }
}

// ── Payment body ──────────────────────────────────────────────────────────────

class _PaymentBody extends StatelessWidget {
  final MatchModel match;
  final bool isRequester;
  final bool loading;
  final bool uploadingReceipt;
  final VoidCallback onMarkPaid;
  final VoidCallback onConfirmPayment;
  final VoidCallback onUploadReceipt;
  final VoidCallback onSetInstructions;

  const _PaymentBody({
    required this.match,
    required this.isRequester,
    required this.loading,
    required this.uploadingReceipt,
    required this.onMarkPaid,
    required this.onConfirmPayment,
    required this.onUploadReceipt,
    required this.onSetInstructions,
  });

  @override
  Widget build(BuildContext context) {
    final amount = match.listingAmount ?? 0.0;
    final fmt = NumberFormat('#,##0', 'en_NG');
    final amountStr = '₦${fmt.format(amount)}';

    final paymentSent = match.requesterPaidAt != null;
    final paymentConfirmed = match.ownerConfirmedAt != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Step indicator ─────────────────────────────────────
                _StepIndicator(
                  paymentSent: paymentSent,
                  paymentConfirmed: paymentConfirmed,
                ),

                const SizedBox(height: 24),

                // ── Amount card ────────────────────────────────────────
                _AmountCard(
                  amountStr: amountStr,
                  listingTitle: match.listingTitle,
                ),

                const SizedBox(height: 16),

                // ── Role-specific content ──────────────────────────────
                if (isRequester)
                  _RequesterView(
                    match: match,
                    paymentSent: paymentSent,
                    uploadingReceipt: uploadingReceipt,
                    onUploadReceipt: onUploadReceipt,
                  )
                else
                  _OwnerView(
                    match: match,
                    paymentSent: paymentSent,
                    paymentConfirmed: paymentConfirmed,
                    onSetInstructions: onSetInstructions,
                  ),

                const SizedBox(height: 24),

                // ── Footer note ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ChipIn escrow payments coming soon for extra security',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
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

        // ── Sticky CTA ─────────────────────────────────────────────────
        _StickyAction(
          match: match,
          isRequester: isRequester,
          loading: loading,
          paymentSent: paymentSent,
          paymentConfirmed: paymentConfirmed,
          amountStr: amountStr,
          onMarkPaid: onMarkPaid,
          onConfirmPayment: onConfirmPayment,
        ),
      ],
    );
  }
}

// ── 3-step progress indicator ─────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final bool paymentSent;
  final bool paymentConfirmed;

  const _StepIndicator({
    required this.paymentSent,
    required this.paymentConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    // Step states: 0=Accepted(always done), 1=Payment Sent, 2=Active
    final step1Done = true; // always done on this screen
    final step2Done = paymentSent;
    final step3Done = paymentConfirmed;

    return Row(
      children: [
        _StepPill(label: 'Accepted', done: step1Done, active: !step2Done),
        _StepLine(done: step2Done),
        _StepPill(
          label: 'Payment Sent',
          done: step2Done,
          active: step1Done && !step2Done,
        ),
        _StepLine(done: step3Done),
        _StepPill(
          label: 'Active',
          done: step3Done,
          active: step2Done && !step3Done,
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StepPill({
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color borderColor;

    if (done) {
      bg = AppColors.success.withValues(alpha: 0.12);
      textColor = AppColors.success;
      borderColor = AppColors.success.withValues(alpha: 0.3);
    } else if (active) {
      bg = AppColors.primary.withValues(alpha: 0.12);
      textColor = AppColors.primary;
      borderColor = AppColors.primary.withValues(alpha: 0.3);
    } else {
      bg = Colors.transparent;
      textColor = AppColors.textMuted;
      borderColor = AppColors.borderSlate;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (done) ...[
              Icon(Icons.check_circle_rounded, size: 12, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: done ? AppColors.success : AppColors.borderSlate,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// ── Amount card ───────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final String amountStr;
  final String? listingTitle;

  const _AmountCard({required this.amountStr, this.listingTitle});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'YOUR SHARE',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountStr,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          if (listingTitle != null) ...[
            const SizedBox(height: 6),
            Text(
              listingTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSub(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Requester (payer) view ────────────────────────────────────────────────────

class _RequesterView extends StatelessWidget {
  final MatchModel match;
  final bool paymentSent;
  final bool uploadingReceipt;
  final VoidCallback onUploadReceipt;

  const _RequesterView({
    required this.match,
    required this.paymentSent,
    required this.uploadingReceipt,
    required this.onUploadReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment instructions card
        if (match.paymentInstructions?.isNotEmpty == true)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PAY VIA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  match.paymentInstructions!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusPendingBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.statusPending.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: AppColors.statusPending,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    'Agree payment details with the owner in chat first',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.statusPending,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Receipt upload card
        _ReceiptUploadCard(
          receiptUrl: match.receiptUrl,
          uploading: uploadingReceipt,
          onUpload: onUploadReceipt,
        ),

        const SizedBox(height: 12),

        // Payment sent status chip
        if (paymentSent) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Marked as Sent',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Waiting for owner to confirm receipt...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.success.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Owner (recipient) view ────────────────────────────────────────────────────

class _OwnerView extends StatelessWidget {
  final MatchModel match;
  final bool paymentSent;
  final bool paymentConfirmed;
  final VoidCallback onSetInstructions;

  const _OwnerView({
    required this.match,
    required this.paymentSent,
    required this.paymentConfirmed,
    required this.onSetInstructions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions card + set button
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'YOUR PAYMENT DETAILS',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onSetInstructions,
                    child: Text(
                      match.paymentInstructions?.isNotEmpty == true
                          ? 'Edit'
                          : 'Set payment details',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                match.paymentInstructions?.isNotEmpty == true
                    ? match.paymentInstructions!
                    : 'Not set — tap "Set payment details" so the requester knows how to pay you.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: match.paymentInstructions?.isNotEmpty == true
                      ? AppColors.textDark
                      : AppColors.textMuted,
                  fontStyle: match.paymentInstructions?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Requester's receipt — show when uploaded
        if (match.receiptUrl?.isNotEmpty == true) ...[
          _ReceiptViewCard(receiptUrl: match.receiptUrl!),
          const SizedBox(height: 12),
        ],

        // Requester payment status card
        if (!paymentSent)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusPendingBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.statusPending.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 16,
                  color: AppColors.statusPending,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Waiting for requester to mark payment as sent',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.statusPending,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (!paymentConfirmed) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match.requesterName ?? "Requester"} marked payment as sent',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Confirm you received the payment to activate the split.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Payment confirmed! Split is now active.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sticky action bar ─────────────────────────────────────────────────────────

class _StickyAction extends StatelessWidget {
  final MatchModel match;
  final bool isRequester;
  final bool loading;
  final bool paymentSent;
  final bool paymentConfirmed;
  final String amountStr;
  final VoidCallback onMarkPaid;
  final VoidCallback onConfirmPayment;

  const _StickyAction({
    required this.match,
    required this.isRequester,
    required this.loading,
    required this.paymentSent,
    required this.paymentConfirmed,
    required this.amountStr,
    required this.onMarkPaid,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Determine label + callback + enabled state
    String label;
    VoidCallback? onTap;
    bool enabled;

    if (paymentConfirmed) {
      // Both sides done — show disabled success state
      label = 'Payment Confirmed';
      onTap = null;
      enabled = false;
    } else if (isRequester) {
      if (paymentSent) {
        label = 'Payment Sent — Awaiting Confirmation';
        onTap = null;
        enabled = false;
      } else {
        label = "I've Sent Payment";
        onTap = loading ? null : onMarkPaid;
        enabled = !loading;
      }
    } else {
      // Owner
      if (!paymentSent) {
        label = 'Confirm Payment Received';
        onTap = null;
        enabled = false;
      } else {
        label = 'Confirm Payment Received';
        onTap = loading ? null : onConfirmPayment;
        enabled = !loading;
      }
    }

    final bgColor = enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.45);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: bgColor,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Go back',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment instructions bottom sheet ────────────────────────────────────────

class _PaymentInstructionsSheet extends ConsumerStatefulWidget {
  final String matchId;
  final String? initialInstructions;
  final VoidCallback onSaved;

  const _PaymentInstructionsSheet({
    required this.matchId,
    this.initialInstructions,
    required this.onSaved,
  });

  @override
  ConsumerState<_PaymentInstructionsSheet> createState() =>
      _PaymentInstructionsSheetState();
}

class _PaymentInstructionsSheetState
    extends ConsumerState<_PaymentInstructionsSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialInstructions ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    setState(() => _saving = true);
    try {
      await ref
          .read(matchNotifierProvider.notifier)
          .acceptMatchWithPaymentInstructions(
            widget.matchId,
            paymentInstructions: text.isEmpty ? null : text,
          );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSlate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Set Payment Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textOn(context),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell the requester how to send you money. E.g. bank details, OPay, or any other method.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _ctrl,
            maxLines: 4,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textOn(context),
            ),
            decoration: InputDecoration(
              hintText:
                  'e.g. GTBank · 0123456789 · John Doe\nor OPay: 08012345678',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Receipt upload card (requester) ──────────────────────────────────────────

class _ReceiptUploadCard extends StatelessWidget {
  final String? receiptUrl;
  final bool uploading;
  final VoidCallback onUpload;

  const _ReceiptUploadCard({
    required this.receiptUrl,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final hasReceipt = receiptUrl?.isNotEmpty == true;
    return GestureDetector(
      onTap: uploading ? null : onUpload,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasReceipt
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border(context),
          ),
        ),
        child: uploading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              )
            : hasReceipt
                ? _ReceiptPreview(receiptUrl: receiptUrl!, onReplace: onUpload)
                : Row(
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Upload Payment Proof',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Optional — screenshot speeds up confirmation',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final String receiptUrl;
  final VoidCallback onReplace;

  const _ReceiptPreview({required this.receiptUrl, required this.onReplace});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: receiptUrl,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(
              width: 52,
              height: 52,
              color: AppColors.border(context),
            ),
            errorWidget: (ctx, url, err) => Container(
              width: 52,
              height: 52,
              color: AppColors.border(context),
              child: const Icon(
                Icons.broken_image_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Receipt Uploaded',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onReplace,
                child: const Text(
                  'Tap to replace',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.success,
        ),
      ],
    );
  }
}

// ── Receipt view card (owner) ─────────────────────────────────────────────────

class _ReceiptViewCard extends StatelessWidget {
  final String receiptUrl;
  const _ReceiptViewCard({required this.receiptUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT PROOF',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: receiptUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(
                height: 180,
                color: AppColors.border(context),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              errorWidget: (ctx, url, err) => Container(
                height: 80,
                color: AppColors.border(context),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
