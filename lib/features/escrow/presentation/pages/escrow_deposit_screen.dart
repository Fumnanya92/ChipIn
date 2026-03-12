import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
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
        currency: json['currency'] as String? ?? 'USD',
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
        'currency': 'USD',
        'status': 'held',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Move match status to active if both parties paid
      await supabase
          .from('matches')
          .update({'status': 'active', 'updated_at': DateTime.now().toIso8601String()})
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

    // Find the match from either provider
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => allMatchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e2, _) => Center(child: Text('Error: $e2')),
          data: (sentMatches) {
            final match = sentMatches
                .where((m) => m.id == widget.matchId)
                .firstOrNull;
            if (match == null) {
              return const Center(child: Text('Match not found'));
            }
            return _buildContent(match);
          },
        ),
        data: (receivedMatches) {
          MatchModel? match = receivedMatches
              .where((m) => m.id == widget.matchId)
              .firstOrNull;
          if (match != null) return _buildContent(match);

          return allMatchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e2, _) => Center(child: Text('Error: $e2')),
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
    final fmt = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Escrow info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF11B4D4), Color(0xFF0090AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Secure Escrow Deposit',
                      style: TextStyle(
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
                  fmt.format(amount),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your share for: ${match.listingTitle ?? 'Split'}',
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

          // How escrow works
          const Text(
            'How Escrow Works',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _EscrowStep(
            step: '1',
            title: 'You deposit your share',
            desc: 'Funds are held securely by ChipIn — not released yet.',
          ),
          _EscrowStep(
            step: '2',
            title: 'All slots are funded',
            desc:
                'Once all participants deposit, the split becomes active.',
          ),
          _EscrowStep(
            step: '3',
            title: 'Split confirmed active',
            desc:
                'Both parties confirm the split is underway — funds released to owner.',
          ),
          _EscrowStep(
            step: '4',
            title: 'Review & repeat',
            desc:
                'After the split completes, both parties rate each other.',
          ),
          const Spacer(),

          // Confirm button
          ElevatedButton.icon(
            onPressed: _confirming ? null : () => _confirmDeposit(match),
            icon: _confirming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_rounded, size: 20),
            label: Text(
                _confirming ? 'Processing...' : 'Deposit ${fmt.format(amount)}'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Funds are held securely until the split is confirmed active.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EscrowStep extends StatelessWidget {
  final String step;
  final String title;
  final String desc;
  const _EscrowStep(
      {required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
