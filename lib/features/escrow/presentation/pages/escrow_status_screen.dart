import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/escrow/presentation/pages/escrow_deposit_screen.dart';
import 'package:chipin/shared/widgets/error_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
          .update({'status': 'released'})
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
            content: Text('Split confirmed! Funds released.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
        context.push('/review/${widget.matchId}');
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
    final fmt = NumberFormat('#,##0.00', 'en_NG');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow Status'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: paymentsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorRetry(
          error: e,
          onRetry: () =>
              ref.invalidate(escrowPaymentsProvider(widget.matchId)),
        ),
        data: (payments) {
          final myPayment = payments
              .where((p) => p.payerId == currentUserId)
              .firstOrNull;
          final totalHeld =
              payments.fold(0.0, (sum, p) => sum + p.amount);
          final allReleased = payments.isNotEmpty &&
              payments.every((p) => p.status == EscrowStatus.released);

          // Derive current step: 0 = no deposits, 1 = deposited/confirmed, 2 = released
          int currentStep = 0;
          if (payments.isNotEmpty) currentStep = 1;
          if (allReleased) currentStep = 2;

          return Column(
            children: [
              // ── Scrollable content ──────────────────────────────────────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    // Progress stepper card
                    _buildProgressStepper(context, currentStep),
                    const SizedBox(height: 14),
                    // Status card
                    _buildStatusCard(context, totalHeld, allReleased, fmt),
                    const SizedBox(height: 14),
                    // Who's In
                    _buildWhosIn(
                        context, payments, currentUserId ?? '', fmt),
                    const SizedBox(height: 14),
                    // How it works
                    _buildHowItWorks(context),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // ── Sticky footer ───────────────────────────────────────────
              _buildFooter(context, myPayment, allReleased),
            ],
          );
        },
      ),
    );
  }

  // ── Progress Stepper ───────────────────────────────────────────────────────

  Widget _buildProgressStepper(BuildContext context, int currentStep) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                'ESCROW PROGRESS',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${currentStep + 1} of 3',
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
          const SizedBox(height: 20),

          // Stepper track + circles
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const circleOuter = 44.0; // ring container size
              const circleInner = 36.0;
              final lineStart = circleOuter / 2;
              final lineEnd = circleOuter / 2;
              final lineWidth = totalWidth - lineStart - lineEnd;
              final progressFraction = (currentStep / 2.0).clamp(0.0, 1.0);

              final steps = [
                _StepInfo(
                  label: 'Deposited',
                  icon: Icons.check_rounded,
                  activeIcon: Icons.check_rounded,
                  state: currentStep > 0
                      ? _StepState.done
                      : currentStep == 0
                          ? _StepState.active
                          : _StepState.future,
                ),
                _StepInfo(
                  label: 'Confirmed',
                  icon: Icons.sync_rounded,
                  activeIcon: Icons.sync_rounded,
                  state: currentStep > 1
                      ? _StepState.done
                      : currentStep == 1
                          ? _StepState.active
                          : _StepState.future,
                ),
                _StepInfo(
                  label: 'Released',
                  icon: Icons.lock_open_rounded,
                  activeIcon: Icons.lock_open_rounded,
                  state: currentStep >= 2 ? _StepState.active : _StepState.future,
                ),
              ];

              return SizedBox(
                height: 70,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background line
                    Positioned(
                      left: lineStart,
                      top: circleOuter / 2 - 1,
                      child: Container(
                        width: lineWidth,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.borderSlate
                              : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Progress line
                    Positioned(
                      left: lineStart,
                      top: circleOuter / 2 - 1,
                      child: Container(
                        width: lineWidth * progressFraction,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Step circles row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.map((step) {
                        final isActive = step.state == _StepState.active;
                        final isDone = step.state == _StepState.done;
                        final isFilled = isActive || isDone;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Outer ring container (uses bg color to fake ring)
                            Container(
                              width: circleOuter,
                              height: circleOuter,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: bgColor,
                              ),
                              child: Center(
                                child: Container(
                                  width: circleInner,
                                  height: circleInner,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.cardDark
                                            : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Icon(
                                    step.icon,
                                    size: 16,
                                    color: isFilled
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isFilled
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Status Card ────────────────────────────────────────────────────────────

  Widget _buildStatusCard(
      BuildContext context, double totalHeld, bool allReleased, NumberFormat fmt) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon area
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          // Text area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AMOUNT HELD',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${fmt.format(totalHeld)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOn(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Active/Held badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      allReleased ? 'Released' : 'Active / Held',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.security_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'Secured by ChipIn',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Who's In ───────────────────────────────────────────────────────────────

  Widget _buildWhosIn(
      BuildContext context,
      List<EscrowPayment> payments,
      String currentUserId,
      NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Who's In",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textOn(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                '${payments.length} participant${payments.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No deposits yet. Waiting for participants.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSub(context),
              ),
            ),
          )
        else
          ...payments.map((p) => _ParticipantRow(
                payment: p,
                isMe: p.payerId == currentUserId,
                fmt: fmt,
              )),
      ],
    );
  }

  // ── How It Works ──────────────────────────────────────────────────────────

  Widget _buildHowItWorks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOn(context),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Funds are held securely in escrow and only released to the final recipient once all parties confirm the split is active and services/goods are rendered.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(
      BuildContext context, EscrowPayment? myPayment, bool allReleased) {
    final canConfirm = myPayment != null &&
        !allReleased &&
        myPayment.status == EscrowStatus.held;
    final needsDeposit = myPayment == null;

    return Container(
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
          // Primary action button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: needsDeposit
                  ? () => context.push('/pay/${widget.matchId}')
                  : allReleased
                      ? null
                      : canConfirm && !_confirming
                          ? () async {
                              // TODO(phase3): For full security, add owner_confirmed_at /
                              // requester_confirmed_at columns to the matches table and
                              // only release escrow via a Postgres trigger when both are set.
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title:
                                      const Text('Confirm Split is Active'),
                                  content: const Text(
                                    'This will release funds to the listing owner and mark the split as completed. '
                                    'Only confirm once the split is genuinely underway.\n\n'
                                    'This cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                      ),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) _confirmSplitActive();
                            }
                          : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allReleased
                    ? AppColors.success
                    : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.textMuted.withValues(alpha: 0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _confirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      needsDeposit
                          ? Icons.account_balance_wallet_rounded
                          : allReleased
                              ? Icons.check_circle_rounded
                              : Icons.lock_open_rounded,
                      size: 20,
                    ),
              label: Text(
                _confirming
                    ? 'Confirming...'
                    : needsDeposit
                        ? 'Deposit Your Share'
                        : allReleased
                            ? 'Funds Released'
                            : 'Confirm Release',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Dispute link
          GestureDetector(
            onTap: () => context.push('/dispute/${widget.matchId}'),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Having issues? ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  TextSpan(
                    text: 'Raise a Dispute',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step data helpers ─────────────────────────────────────────────────────────

enum _StepState { done, active, future }

class _StepInfo {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final _StepState state;
  const _StepInfo({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.state,
  });
}

// ── Participant Row ───────────────────────────────────────────────────────────

class _ParticipantRow extends StatelessWidget {
  final EscrowPayment payment;
  final bool isMe;
  final NumberFormat fmt;

  const _ParticipantRow(
      {required this.payment, required this.isMe, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final name = isMe ? 'You' : 'Split Partner';
    final initial = name[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateMid : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.primaryLight,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + share
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOn(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₦${fmt.format(payment.amount)} share • Deposited',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Check icon
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }
}
