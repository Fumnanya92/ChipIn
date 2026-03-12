import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _submittingPayment = false;

  Future<void> _startPhoneVerification(bool alreadyVerified) async {
    if (alreadyVerified) return;
    final phoneCtrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Your Phone',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your phone number and we\'ll send you a verification code.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '+234 800 000 0000',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(ctx, phoneCtrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    phoneCtrl.dispose();
    if (result != null && result.isNotEmpty && mounted) {
      context.push('/otp', extra: {
        'phone': result,
        'fullName': '',
        'email': '',
        'password': '',
      });
    }
  }

  Future<void> _startIdVerification() async {
    context.push('/verify/intro');
  }

  Future<void> _startPaymentVerification() async {
    setState(() => _submittingPayment = true);
    // Phase 3: integrate Paystack / Flutterwave card verification.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _submittingPayment = false);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Payment Verification'),
        content: const Text(
          'In Phase 3, this will launch the Paystack payment flow where you can '
          'add and verify a payment method (card or bank account).\n\n'
          'You will earn +20 trust score points upon successful verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider('me'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Identity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Trust Score bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.shield_rounded,
                        size: 36, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      '${(profile?.trustScore ?? 0).toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Trust Score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (profile?.trustScore ?? 0) / 100,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Verification Layers',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Each layer makes your profile more trusted by others.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Layer 1: Phone (always done at signup)
              _VerificationTile(
                icon: Icons.phone_rounded,
                title: 'Phone Verified',
                subtitle:
                    'Earns +20 trust points · Verified at signup via Termii OTP',
                points: '+20 pts',
                isDone: profile?.phoneVerified ?? false,
                isLoading: false,
                onTap: (profile?.phoneVerified ?? false)
                    ? null
                    : () => _startPhoneVerification(
                          profile?.phoneVerified ?? false,
                        ),
              ),
              const SizedBox(height: 12),

              // Layer 2: ID / KYC (Stripe Identity — Phase 2)
              _VerificationTile(
                icon: Icons.badge_rounded,
                title: 'ID Verification',
                subtitle:
                    'Earns +40 trust points · Upload government ID + selfie',
                points: '+40 pts',
                isDone: profile?.idVerified ?? false,
                isLoading: false,
                onTap: (profile?.idVerified ?? false)
                    ? null
                    : _startIdVerification,
                badgeLabel: 'Phase 2',
              ),
              const SizedBox(height: 12),

              // Layer 3: Payment (Paystack — Phase 3)
              _VerificationTile(
                icon: Icons.credit_card_rounded,
                title: 'Payment Verified',
                subtitle:
                    'Earns +20 trust points · Add a valid card or bank account',
                points: '+20 pts',
                isDone: profile?.paymentVerified ?? false,
                isLoading: _submittingPayment,
                onTap: (profile?.paymentVerified ?? false)
                    ? null
                    : _startPaymentVerification,
                badgeLabel: 'Phase 3',
              ),
              const SizedBox(height: 24),

              // Score breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How Trust Score is Built',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ScoreRow('📱 Phone Verified', '+20 pts'),
                    _ScoreRow('🪪 ID Verified (KYC)', '+40 pts'),
                    _ScoreRow('💳 Payment Verified', '+20 pts'),
                    _ScoreRow('⭐ Trusted User (4.5+ rating, 5+ splits)',
                        '+20 pts'),
                    _ScoreRow('✅ Each Completed Split', '+2 pts'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String points;
  final bool isDone;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? badgeLabel;

  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.isDone,
    required this.isLoading,
    required this.onTap,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.success : AppColors.borderLight,
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDone ? AppColors.success : AppColors.primary,
            size: 22,
          ),
        ),
        title: Row(
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
            const SizedBox(width: 8),
            if (badgeLabel != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              points,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDone ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
        trailing: isDone
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 26)
            : isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : onTap == null
                    ? null
                    : const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
        onTap: isLoading || isDone ? null : onTap,
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String points;
  const _ScoreRow(this.label, this.points);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
