import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A reusable error state widget with a retry button.
/// Use this in all AsyncValue.when(error:...) handlers instead of
/// displaying raw exception strings to users.
class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String? message;

  const ErrorRetry({
    super.key,
    required this.error,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
