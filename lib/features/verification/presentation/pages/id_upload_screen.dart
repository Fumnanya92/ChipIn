import 'dart:io';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class IdUploadScreen extends StatefulWidget {
  const IdUploadScreen({super.key});

  @override
  State<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends State<IdUploadScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDocType = 0;
  File? _capturedImage;
  bool _isLoading = false;

  late final AnimationController _scanCtrl = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _scanAnim = CurvedAnimation(
    parent: _scanCtrl,
    curve: Curves.easeInOut,
  );

  static const _docTypes = ['Passport', "Driver's License", 'National ID'];

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file != null) {
      setState(() => _capturedImage = File(file.path));
    }
  }

  Future<void> _submit() async {
    if (_capturedImage == null) return;
    setState(() => _isLoading = true);
    // TODO Phase 2: Upload to Supabase Storage and submit to KYC provider.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.push('/verify/selfie');
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
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
                  Expanded(
                    child: Text(
                      'ID Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  // Balance back button so title is truly centred
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ── Linear progress section ───────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Document Upload',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Step 1 of 3',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: 1 / 3,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Heading
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Scan your ID',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Please select your document type and capture a clear '
                        'photo of the front side. Ensure all details are legible.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Document-type tab bar ─────────────────────────────
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                AppColors.primary.withValues(alpha: 0.10),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: List.generate(_docTypes.length, (i) {
                          final active = _selectedDocType == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDocType = i),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: active
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _docTypes[i],
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? AppColors.primary
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Scanner frame ─────────────────────────────────────
                    AspectRatio(
                      aspectRatio: 1.586,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final frameH = constraints.maxHeight;
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A2535)
                                  : const Color(0xFFEEF2F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.30),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                children: [
                                  // Subtle radial gradient wash
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: Alignment.center,
                                          radius: 0.9,
                                          colors: [
                                            AppColors.primary
                                                .withValues(alpha: 0.06),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Captured image or placeholder
                                  if (_capturedImage != null)
                                    Positioned.fill(
                                      child: Image.file(
                                        _capturedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.photo_camera_rounded,
                                              color: AppColors.primary,
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Position ID within frame',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? const Color(0xFF64748B)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Corner L-brackets
                                  _IdCorner(
                                      top: 10,
                                      left: 10,
                                      isTop: true,
                                      isLeft: true),
                                  _IdCorner(
                                      top: 10,
                                      right: 10,
                                      isTop: true,
                                      isLeft: false),
                                  _IdCorner(
                                      bottom: 10,
                                      left: 10,
                                      isTop: false,
                                      isLeft: true),
                                  _IdCorner(
                                      bottom: 10,
                                      right: 10,
                                      isTop: false,
                                      isLeft: false),

                                  // Animated horizontal scan line
                                  if (_capturedImage == null)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _scanAnim,
                                        builder: (_, _) => Stack(
                                          children: [
                                            Positioned(
                                              top: _scanAnim.value *
                                                  (frameH - 2),
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 2,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.50),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.primary,
                                                      blurRadius: 15,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Capture Photo ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 22),
                        label: const Text('Capture Photo'),
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
                    const SizedBox(height: 12),

                    // ── Upload from Gallery ───────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: Icon(
                          Icons.upload_file_rounded,
                          size: 22,
                          color: textPrimary,
                        ),
                        label: Text(
                          'Upload from Gallery',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                          foregroundColor: textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    // ── Next button (appears after image captured) ────────
                    if (_capturedImage != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Next',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Security badge ────────────────────────────────────
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.20),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Your data is encrypted and secure',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ── Corner bracket widget ─────────────────────────────────────────────────────

class _IdCorner extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool isTop;
  final bool isLeft;

  const _IdCorner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: SizedBox(
        width: 32,
        height: 32,
        child: CustomPaint(
          painter: _BracketPainter(
            isTop: isTop,
            isLeft: isLeft,
            color: AppColors.primary,
            strokeWidth: 4,
          ),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;
  final double strokeWidth;

  const _BracketPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final ex = isLeft ? size.width : 0.0;
    final ey = isTop ? size.height : 0.0;

    canvas.drawLine(Offset(x, y), Offset(ex, y), paint); // horizontal arm
    canvas.drawLine(Offset(x, y), Offset(x, ey), paint); // vertical arm
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
