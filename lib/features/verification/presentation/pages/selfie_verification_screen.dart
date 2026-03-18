import 'dart:io';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class SelfieVerificationScreen extends ConsumerStatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  ConsumerState<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState
    extends ConsumerState<SelfieVerificationScreen>
    with TickerProviderStateMixin {
  File? _selfieImage;
  bool _isSubmitting = false;

  // Scan line: animates 0 → 1 → 0 (top to bottom and back)
  late final AnimationController _scanCtrl = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _scanAnim = CurvedAnimation(
    parent: _scanCtrl,
    curve: Curves.easeInOut,
  );

  // Oval ring pulse (opacity / glow)
  late final AnimationController _pulseCtrl = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnim = CurvedAnimation(
    parent: _pulseCtrl,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureSelfie() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (file != null) {
      setState(() => _selfieImage = File(file.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file != null) {
      setState(() => _selfieImage = File(file.path));
    }
  }

  void _retake() => setState(() => _selfieImage = null);

  Future<void> _submit() async {
    if (_selfieImage == null) return;
    setState(() => _isSubmitting = true);

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated'))
          );
        }
        return;
      }

      // Upload selfie to Supabase Storage
      await supabaseService.uploadSelfie(
        userId: userId,
        imageFile: _selfieImage!,
      );

      // Mark user as ID verified and update trust score
      await supabaseService.markIdVerified(userId);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}'))
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Show success sheet then go back to main verify screen.
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SuccessSheet(),
    );
    if (!mounted) return;
    context.go('/verify');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textOn(context);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom AppBar: ← | IDENTITY CHECK + dots | ? ─────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),

                  // Center: "IDENTITY CHECK" + 3 progress dots
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'IDENTITY CHECK',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Step 1 – active
                            Container(
                              height: 4,
                              width: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Step 2 – active
                            Container(
                              height: 4,
                              width: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Step 3 – inactive
                            Container(
                              height: 4,
                              width: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Help button (decorative)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                child: Column(
                  children: [
                    // Heading
                    Text(
                      'Selfie Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Position your face within the frame and ensure\n'
                      'your features are clearly visible.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Camera viewport (3:4 rounded-3xl + oval guide) ────
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final vpW = constraints.maxWidth;
                          final vpH = constraints.maxHeight;
                          final ovalW = vpW * 0.62;
                          final ovalH = ovalW * 1.30;
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A2535)
                                  : const Color(0xFF263040),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.20),
                                width: 4,
                              ),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Background: captured image or face icon
                                if (_selfieImage != null)
                                  Positioned.fill(
                                    child: Image.file(
                                      _selfieImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Center(
                                    child: Icon(
                                      Icons.face_rounded,
                                      size: 88,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.22),
                                    ),
                                  ),

                                // 2. Animated scan line (below dark overlay —
                                //    visible only through the oval hole)
                                if (_selfieImage == null)
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _scanAnim,
                                      builder: (_, _) => Stack(
                                        children: [
                                          Positioned(
                                            top: _scanAnim.value *
                                                (vpH - 2),
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 2,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    AppColors.primary
                                                        .withValues(
                                                            alpha: 0.70),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // 3. Dark overlay with transparent oval hole
                                if (_selfieImage == null)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _OvalOverlayPainter(
                                        ovalWidth: ovalW,
                                        ovalHeight: ovalH,
                                      ),
                                    ),
                                  ),

                                // 4. Oval ring border (with pulse glow)
                                AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (_, _) => Container(
                                    width: ovalW,
                                    height: ovalH,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.elliptical(
                                            ovalW / 2, ovalH / 2),
                                      ),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(
                                                  alpha: 0.28 +
                                                      _pulseAnim.value *
                                                          0.28),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 5. Corner L-brackets
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: _SelfieCornerWidget(
                                      isTop: true, isLeft: true),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: _SelfieCornerWidget(
                                      isTop: true, isLeft: false),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: _SelfieCornerWidget(
                                      isTop: false, isLeft: true),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: _SelfieCornerWidget(
                                      isTop: false, isLeft: false),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Capture controls / Review state ───────────────────
                    if (_selfieImage == null) ...[
                      // 3-button capture row: gallery | large capture | flip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gallery
                          GestureDetector(
                            onTap: _pickFromGallery,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.photo_library_rounded,
                                size: 22,
                                color: isDark
                                    ? AppColors.textSubtle
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Main capture button (80px inner, 96px outer ring)
                          GestureDetector(
                            onTap: _captureSelfie,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.20),
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.40),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Flip camera
                          GestureDetector(
                            onTap: _captureSelfie,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.flip_camera_ios_rounded,
                                size: 22,
                                color: isDark
                                    ? AppColors.textSubtle
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // "Capture Selfie" full-width button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _captureSelfie,
                          icon: const Icon(Icons.camera_alt_rounded, size: 22),
                          label: const Text('Capture Selfie'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Review state: Retake + Submit
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _retake,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Retake'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      )
                                    : const Text('Submit'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Tips grid 2×2 ─────────────────────────────────────
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TipCard(
                                icon: Icons.wb_sunny_rounded,
                                title: 'Good Lighting',
                                subtitle: 'Avoid shadows on face',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TipCard(
                                icon: Icons.visibility_rounded,
                                title: 'Face Forward',
                                subtitle: 'Eyes facing camera',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TipCard(
                                icon: Icons.remove_circle_outline_rounded,
                                title: 'No Glasses',
                                subtitle: 'Ensure eyes are visible',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TipCard(
                                icon: Icons.do_not_disturb_on_rounded,
                                title: 'Remove Hat',
                                subtitle: 'Full head must be visible',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Privacy disclaimer ────────────────────────────────
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: textSecondary,
                          height: 1.6,
                        ),
                        children: const [
                          TextSpan(
                            text:
                                'Your biometric data is encrypted and used only for ID verification. ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dark overlay with transparent oval hole ───────────────────────────────────

class _OvalOverlayPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;

  const _OvalOverlayPainter({
    required this.ovalWidth,
    required this.ovalHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw dark overlay across entire viewport
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF101F22).withValues(alpha: 0.70),
    );

    // Punch out the oval area (becomes transparent — allows layers beneath
    // to show through, including the scan line and placeholder icon)
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );
    canvas.drawOval(
      ovalRect,
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OvalOverlayPainter old) =>
      old.ovalWidth != ovalWidth || old.ovalHeight != ovalHeight;
}

// ── Corner bracket widget ─────────────────────────────────────────────────────

class _SelfieCornerWidget extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _SelfieCornerWidget({
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _SelfieBracketPainter(isTop: isTop, isLeft: isLeft),
      ),
    );
  }
}

class _SelfieBracketPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  const _SelfieBracketPainter({
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final ex = isLeft ? size.width : 0.0;
    final ey = isTop ? size.height : 0.0;

    canvas.drawLine(Offset(x, y), Offset(ex, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, ey), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Tip card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color:
            AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFE2E8F0)
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success bottom sheet ──────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDCFCE7),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verification Submitted!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? const Color(0xFFE2E8F0)
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "We'll review your submission within 24 hours. You'll be "
            'notified once approved and your trust score will be updated.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Back to Profile',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
