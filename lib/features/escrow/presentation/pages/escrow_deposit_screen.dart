import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:chipin/shared/widgets/error_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── Escrow payment model (local) ──────────────────────────────────────────────

enum EscrowStatus { held, released, refunded }

class EscrowPayment {
  final String id;
  final String matchId;
  final String payerId;
  final double amount;
  final String currency;
  final EscrowStatus status;
  final String? paymentRef;
  final DateTime createdAt;

  const EscrowPayment({
    required this.id,
    required this.matchId,
    required this.payerId,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentRef,
    required this.createdAt,
  });

  factory EscrowPayment.fromJson(Map<String, dynamic> json) => EscrowPayment(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        payerId: json['payer_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'NGN',
        status: EscrowStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EscrowStatus.held,
        ),
        paymentRef: json['payment_ref'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ── Escrow provider ────────────────────────────────────────────────────────────

final escrowPaymentsProvider =
    FutureProvider.autoDispose.family<List<EscrowPayment>, String>(
  (ref, matchId) async {
    final supabase = ref.read(supabaseClientProvider);
    final data = await supabase
        .from('escrow_payments')
        .select()
        .eq('match_id', matchId)
        .order('created_at');
    return (data as List)
        .map((r) => EscrowPayment.fromJson(r as Map<String, dynamic>))
        .toList();
  },
);

// ── Escrow Deposit Screen ─────────────────────────────────────────────────────

class EscrowDepositScreen extends ConsumerStatefulWidget {
  final String matchId;
  const EscrowDepositScreen({super.key, required this.matchId});

  @override
  ConsumerState<EscrowDepositScreen> createState() =>
      _EscrowDepositScreenState();
}

class _EscrowDepositScreenState extends ConsumerState<EscrowDepositScreen> {
  bool _confirming = false;
  String _selectedPaymentMethod = 'card';

  Future<void> _confirmDeposit(MatchModel match) async {
    setState(() => _confirming = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final amount = match.listingAmount ?? 0.0;

      await supabase.from('escrow_payments').insert({
        'match_id': widget.matchId,
        'payer_id': userId,
        'amount': amount,
        'currency': 'NGN',
        'status': 'held',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Move match status to active once deposit is made
      await supabase
          .from('matches')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.matchId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit confirmed! Funds held in escrow.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pushReplacement('/escrow/${widget.matchId}');
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
    final matchesAsync = ref.watch(receivedMatchesProvider);
    final allMatchesAsync = ref.watch(sentMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow Deposit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: matchesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => allMatchesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e2, _) => ErrorRetry(
            error: e2,
            onRetry: () => ref.invalidate(sentMatchesProvider),
          ),
          data: (sentMatches) {
            final match =
                sentMatches.where((m) => m.id == widget.matchId).firstOrNull;
            if (match == null) {
              return const Center(child: Text('Match not found'));
            }
            return _buildContent(match);
          },
        ),
        data: (receivedMatches) {
          MatchModel? match =
              receivedMatches.where((m) => m.id == widget.matchId).firstOrNull;
          if (match != null) return _buildContent(match);

          return allMatchesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e2, _) => ErrorRetry(
              error: e2,
              onRetry: () => ref.invalidate(sentMatchesProvider),
            ),
            data: (sentMatches) {
              match =
                  sentMatches.where((m) => m.id == widget.matchId).firstOrNull;
              if (match == null) {
                return const Center(child: Text('Match not found'));
              }
              return _buildContent(match!);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(MatchModel match) {
    final amount = match.listingAmount ?? 0.0;
    final fmt = NumberFormat('#,##0.00', 'en_NG');
    final amountStr = '₦${fmt.format(amount)}';
    final isDark = AppColors.isDark(context);

    return Column(
      children: [
        // ── Scrollable content ────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary card ──────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      // Hero section
                      SizedBox(
                        height: 120,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Category icon
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  Icons.subscriptions_rounded,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Amount section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          children: [
                            // "TOTAL AMOUNT DUE" label
                            Text(
                              'TOTAL AMOUNT DUE',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            // Amount
                            Text(
                              amountStr,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textOn(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Divider(
                              color: AppColors.border(context),
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 14),
                            // Listing name row + ACTIVE chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        match.listingTitle ?? 'Split',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textOn(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Monthly Subscription',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
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
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Security box ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusActiveBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.statusActive.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.statusActive
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: AppColors.statusActive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Secure Escrow Payment',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusActive,
                              ),
                            ),
                            Text(
                              'Verified by ChipIn Security',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.statusActive
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 20,
                        color: AppColors.statusActive,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Payment Method section ────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOn(context),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // TODO(phase3): Add payment method flow
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Add payment method coming soon')),
                        );
                      },
                      child: const Text(
                        'Add New',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment option 1: Card
                _PaymentOptionRow(
                  id: 'card',
                  icon: Icons.credit_card_rounded,
                  title: 'Debit / Credit Card',
                  subtitle: 'Powered by Paystack',
                  selected: _selectedPaymentMethod == 'card',
                  onTap: () => setState(() => _selectedPaymentMethod = 'card'),
                ),

                // Payment option 2: Bank Transfer
                _PaymentOptionRow(
                  id: 'bank',
                  icon: Icons.account_balance_rounded,
                  title: 'Bank Transfer',
                  subtitle: 'Fast and secure',
                  selected: _selectedPaymentMethod == 'bank',
                  onTap: () => setState(() => _selectedPaymentMethod = 'bank'),
                ),

                const SizedBox(height: 12),

                // ── Info text ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Funds are held securely by ChipIn and only released to the group creator once the split is active and verified. You can request a refund if the split doesn\'t start.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Sticky bottom bar ─────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg(context),
            border: Border(
              top: BorderSide(color: AppColors.border(context)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pay button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _confirming ? null : () => _confirmDeposit(match),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _confirming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pay $amountStr',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Cancel and go back',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Payment Option Row ────────────────────────────────────────────────────────

class _PaymentOptionRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionRow({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slateMid
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.textSubtle : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOn(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Custom radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.borderSlate,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
