import 'dart:io';

import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/features/post/presentation/pages/post_category_screen.dart'
    show PostProgressBar;
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashed border custom painter
// ─────────────────────────────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth,
          size.height - strokeWidth),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      color != old.color || borderRadius != old.borderRadius;
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Extras Screen — Step 3 of 3
// ─────────────────────────────────────────────────────────────────────────────
class PostExtrasScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> listingData;
  const PostExtrasScreen({super.key, required this.listingData});

  @override
  ConsumerState<PostExtrasScreen> createState() => _PostExtrasScreenState();
}

class _PostExtrasScreenState extends ConsumerState<PostExtrasScreen> {
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final List<String> _tags = [];
  XFile? _pickedImage;
  bool _isPublishing = false;
  bool _showTagInput = false;

  static const _presetTags = [
    'Non-smoker',
    'Students ok',
    'Professionals',
    'Pet-friendly',
    'No parties',
    'Couples welcome',
    'LGBTQ+ friendly',
    'Early riser',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _addTag([String? customTag]) {
    final tag = (customTag ?? _tagCtrl.text).trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
        _showTagInput = false;
      });
    } else {
      setState(() => _showTagInput = false);
    }
  }

  void _togglePreset(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _pickedImage = picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not pick image: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName =
          'listing_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'listings/$userId/$fileName';
      final bytes = await _pickedImage!.readAsBytes();

      await supabase.storage.from('listing-images').uploadBinary(
            storagePath,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg'),
          );

      return supabase.storage
          .from('listing-images')
          .getPublicUrl(storagePath);
    } catch (_) {
      // Image upload failure is non-fatal
      return null;
    }
  }

  Future<void> _publish({bool draft = false}) async {
    setState(() => _isPublishing = true);
    try {
      final imageUrl = await _uploadImage();
      final data = {
        ...widget.listingData,
        'description': _descCtrl.text.trim(),
        'tags': _tags,
        'status': draft ? 'paused' : 'active',
        // ignore: use_null_aware_elements
        if (imageUrl != null) 'image_url': imageUrl,
      };
      await ref.read(listingsNotifierProvider.notifier).createListing(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(draft ? 'Listing saved as draft.' : 'Your split is now live!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'apartment':
        return Icons.home_rounded;
      case 'subscription':
        return Icons.subscriptions_rounded;
      case 'carpool':
        return Icons.directions_car_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'office':
        return Icons.work_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  String _fmtAmt(double v) {
    if (v == 0) return '0';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textOnColor = isDark ? AppColors.textDark : AppColors.textPrimary;
    final appBarBg = isDark ? const Color(0xFF111C1E) : Colors.white;
    final footerBg = isDark ? const Color(0xFF111C1E) : Colors.white;
    final footerBorderColor =
        isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.borderLight;

    // Listing data
    final amount =
        (widget.listingData['split_amount'] as num?)?.toDouble() ?? 0;
    final title = widget.listingData['title'] as String? ?? '';
    final location = widget.listingData['location'] as String? ?? '';
    final category = widget.listingData['category'] as String? ?? 'other';
    final categoryModel = ListingCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => ListingCategory.other,
    );

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111C1E) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textOnColor, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post a Split - Finish',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textOnColor,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: footerBg,
            border: Border(
              top: BorderSide(color: footerBorderColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Publish Split
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isPublishing ? null : () => _publish(draft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Publish Split',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              // Save as Draft
              TextButton(
                onPressed:
                    _isPublishing ? null : () => _publish(draft: true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text(
                  'Save as Draft',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          // Progress bar
          PostProgressBar(step: 3),

          // ── Cover Image ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cover Image',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textOnColor,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      strokeWidth: 1.5,
                      dashWidth: 6.0,
                      dashSpace: 4.0,
                      borderRadius: 12.0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: _pickedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 36,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Add a photo',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Optional — JPG, PNG up to 5MB',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_pickedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _pickedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Description ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textOnColor,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: null,
                  minLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: textOnColor,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tell potential partners about the split — requirements, details, expectations...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A2B2E)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.transparent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    counterStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          // ── Tags ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tags',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textOnColor,
                  ),
                ),
                const SizedBox(height: 10),

                // Selected tags + Add tag button
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Existing tags
                    ..._tags.map(
                      (t) => _TagChip(
                        label: t,
                        onRemove: () => setState(() => _tags.remove(t)),
                      ),
                    ),
                    // Add tag input or button
                    if (_showTagInput)
                      _AddTagInput(
                        controller: _tagCtrl,
                        onAdd: () => _addTag(),
                        onCancel: () => setState(() {
                          _showTagInput = false;
                          _tagCtrl.clear();
                        }),
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _showTagInput = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_rounded,
                                  size: 15, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Add tag',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
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
                const SizedBox(height: 14),

                // Suggested preset tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetTags
                      .where((t) => !_tags.contains(t))
                      .map(
                        (t) => GestureDetector(
                          onTap: () => _togglePreset(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // ── Preview Listing ──────────────────────────────────────────────
          const SizedBox(height: 28),
          Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREVIEW LISTING',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image / placeholder
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image or gradient placeholder
                              _pickedImage != null
                                  ? Image.file(
                                      File(_pickedImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary
                                                .withValues(alpha: 0.15),
                                            AppColors.primary
                                                .withValues(alpha: 0.05),
                                          ],
                                        ),
                                        color: isDark
                                            ? const Color(0xFF1E3035)
                                            : AppColors.backgroundLight,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _iconForCategory(category),
                                          size: 48,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                              // Category badge top-left
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    categoryModel.label.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Price badge top-right
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF111C1E)
                                            .withValues(alpha: 0.95)
                                        : Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '₦${_fmtAmt(amount)}/mo',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Card content
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty ? 'Your listing title' : title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textOnColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  location.isEmpty ? 'Location' : location,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (_tags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _tags
                                    .take(3)
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          t,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag chip widget
// ─────────────────────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline tag input widget
// ─────────────────────────────────────────────────────────────────────────────
class _AddTagInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const _AddTagInput({
    required this.controller,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  State<_AddTagInput> createState() => _AddTagInputState();
}

class _AddTagInputState extends State<_AddTagInput> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textOnColor = isDark ? AppColors.textDark : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: widget.controller,
              autofocus: true,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: textOnColor,
              ),
              decoration: const InputDecoration(
                hintText: 'Type a tag...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onSubmitted: (_) => widget.onAdd(),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
