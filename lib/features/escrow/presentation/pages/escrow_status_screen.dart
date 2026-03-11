import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/escrow/presentation/pages/escrow_deposit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class EscrowStatusScreen extends ConsumerStatefulWidget {
  final String matchId;
  const EscrowStatusScreen({super.key, required this.matchId});

  @override
  ConsumerState<EscrowStatusScreen> createState() =>
      _EscrowStatusScreenState();
}

class _EscrowStatusScreenState extends ConsumerState<EscrowStatusScreen> {
  bool _confirming = false;

  Future<void> _confirmSplitActive() async {
    setState(() => _confirming = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('escrow_payments')
          .update({
            'status': 'released',
          })
          .eq('match_id', widget.matchId)
          .eq('status', 'held');

      await supabase
          .from('matches')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.matchId);

      ref.invalidate(escrowPaymentsProvider(widget.matchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split confirmed! Funds released. Please leave a review.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(escrowPaymentsProvider(widget.matchId));
    final currentUserId = ref.read(currentUserIdProvider);
    final fmt = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Escrow Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_rounded, color: AppColors.error),
            tooltip: 'Raise dispute',
            onPressed: () => context.push('/dispute/${widget.matchId}'),
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payments) {
          final myPayment = payments
              .where((p) => p.payerId == currentUserId)
              .firstOrNull;
          final totalHeld =
              payments.fold(0.0, (sum, p) => sum + p.amount);
          final allReleased =
              payments.isNotEmpty &&
              payments.every((p) => p.status == EscrowStatus.released);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Status card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: allReleased
                      ? AppColors.success
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          allReleased
                              ? Icons.check_circle_rounded
                              : Icons.lock_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          allReleased ? 'Funds Released' : 'Funds Held in Escrow',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fmt.format(totalHeld),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total ${allReleased ? 'released' : 'held'} across ${payments.length} payment${payments.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment rows
              const Text(
                'Payment Breakdown',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (payments.isEmpty)
                const Text(
                  'No payments yet. Waiting for participants to deposit.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...payments.map((p) => _PaymentRow(
                      payment: p,
                      isMe: p.payerId == currentUserId,
                      fmt: fmt,
                    )),

              const SizedBox(height: 24),

              // My deposit status
              if (myPayment == null) ...[
                const Text(
                  'You have not deposited yet.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      context.push('/pay/${widget.matchId}'),
                  child: const Text('Deposit My Share'),
                ),
              ] else if (!allReleased && myPayment.status == EscrowStatus.held) ...[
                const Divider(height: 32),
                const Text(
                  'Confirm Split is Active',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Once you confirm the split is active, funds will be released to the listing owner.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      _confirming ? null : _confirmSplitActive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  icon: _confirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                      _confirming ? 'Confirming...' : 'Confirm Split is Active'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/dispute/${widget.matchId}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: const Text('Raise a Dispute'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final EscrowPayment payment;
  final bool isMe;
  final NumberFormat fmt;

  const _PaymentRow(
      {required this.payment, required this.isMe, required this.fmt});

  Color get _statusColor {
    switch (payment.status) {
      case EscrowStatus.held:
        return AppColors.warning;
      case EscrowStatus.released:
        return AppColors.success;
      case EscrowStatus.refunded:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_rounded,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Your deposit' : 'Their deposit',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  timeago.format(payment.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(payment.amount),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  payment.status.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
