import 'dart:async';
import 'package:chipin/core/config/app_constants.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/shared/services/termii_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String fullName;
  final String email;
  final String password;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _pinId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMsg;
  int _resendTimer = AppConstants.otpResendCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = AppConstants.otpResendCooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer <= 0) {
        t.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    try {
      final result = await TermiiService.sendOtp(widget.phoneNumber);
      _pinId = result['pinId'] as String?;
      _startResendTimer();
    } catch (e) {
      setState(() => _errorMsg = 'Failed to send OTP. Check your number.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verify() async {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length < 6) {
      setState(() => _errorMsg = 'Enter the 6-digit code');
      return;
    }
    if (_pinId == null) {
      setState(() => _errorMsg = 'OTP not sent. Tap Resend.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final verified =
          await TermiiService.verifyOtp(pinId: _pinId!, pin: pin);
      if (!mounted) return;
      if (verified) {
        await ref.read(authNotifierProvider.notifier).markPhoneVerified();
        if (!mounted) return;
        // When called from signup flow (email present) go to home.
        // When called from verification screen (email empty) just pop back.
        if (widget.email.isNotEmpty) {
          context.go('/home');
        } else {
          context.pop();
        }
      } else {
        setState(() => _errorMsg = 'Incorrect code. Try again.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Verification failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Enter OTP Code',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSending
                  ? 'Sending code to ${widget.phoneNumber}...'
                  : 'Code sent to ${widget.phoneNumber}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),

            // 6-digit OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextFormField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      if (i == 5 && val.isNotEmpty) _verify();
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verify,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verify'),
            ),
            const SizedBox(height: 16),
            Center(
              child: _resendTimer > 0
                  ? Text(
                      'Resend in ${_resendTimer}s',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    )
                  : TextButton(
                      onPressed: _isSending ? null : _sendOtp,
                      child: const Text('Resend code'),
                    ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
