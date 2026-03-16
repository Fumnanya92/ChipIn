import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/features/matches/presentation/providers/match_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _isRequesting = false;
  bool _hasRequested = false;

  Future<void> _showRequestDialog(ListingModel listing) async {
    final messageCtrl = TextEditingController();
    final isDark = AppColors.isDark(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.cardDark : AppColors.surfaceLight,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Request to Join',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Introduce yourself to the owner (optional)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Hi, I'd love to join this split...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    final msg = messageCtrl.text.trim();
    messageCtrl.dispose();

    if (confirmed == true) {
      await _requestToJoin(listing, message: msg.isEmpty ? null : msg);
    }
  }

  Future<void> _requestToJoin(ListingModel listing,
      {String? message}) async {
    // Guard: never allow requesting a split on your own listing
    final uid = ref.read(currentUserIdProvider);
    if (uid == null || uid == listing.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot request your own listing.')),
      );
      return;
    }
    setState(() => _isRequesting = true);
    try {
      await ref.read(matchNotifierProvider.notifier).requestToJoin(
            listing.id,
            listing.userId,
            message: message,
          );
      if (!mounted) return;
      setState(() => _hasRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! The owner will get back to you.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  // ── Edit sheet (owner only) ──────────────────────────────────────────────
  void _showEditSheet(ListingModel listing) {
    final isDark = AppColors.isDark(context);
    final titleCtrl = TextEditingController(text: listing.title);
    final descCtrl =
        TextEditingController(text: listing.description ?? '');
    final splitAmountCtrl = TextEditingController(
      text: listing.splitAmount == listing.splitAmount.truncateToDouble()
          ? listing.splitAmount.toInt().toString()
          : listing.splitAmount.toStringAsFixed(2),
    );
    final slotsCtrl =
        TextEditingController(text: listing.slotsTotal.toString());
    bool isSaving = false;
    bool isActive = listing.status == ListingStatus.active;
    XFile? newImage;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111C1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Listing',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Cover Photo ────────────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1200,
                        maxHeight: 900,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        setSheetState(() => newImage = picked);
                      }
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.borderSlate
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(12),
                        image: newImage != null
                            ? DecorationImage(
                                image: FileImage(File(newImage!.path)),
                                fit: BoxFit.cover,
                              )
                            : listing.imageUrl != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        listing.imageUrl!,
                                        cacheKey: listing.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (newImage == null && listing.imageUrl == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 32, color: AppColors.textMuted),
                                const SizedBox(height: 6),
                                const Text('Add Cover Photo',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    )),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Change',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  _EditField(
                      label: 'Title',
                      controller: titleCtrl,
                      isDark: isDark),
                  const SizedBox(height: 14),

                  // Description
                  _EditField(
                    label: 'Description',
                    controller: descCtrl,
                    isDark: isDark,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),

                  // Split Amount + Slots row
                  Row(
                    children: [
                      Expanded(
                        child: _EditField(
                          label: 'Split Amount (₦)',
                          controller: splitAmountCtrl,
                          isDark: isDark,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EditField(
                          label: 'Total Slots',
                          controller: slotsCtrl,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status toggle
                  Row(
                    children: [
                      Text(
                        'Listing Status',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setSheetState(() => isActive = !isActive),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                      .withValues(alpha: 0.35)
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 14,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? 'Active' : 'Paused',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              try {
                                final splitAmt =
                                    double.tryParse(
                                            splitAmountCtrl.text.trim()) ??
                                        listing.splitAmount;
                                final slots =
                                    int.tryParse(slotsCtrl.text.trim()) ??
                                        listing.slotsTotal;

                                // Upload new cover image if picked
                                String? uploadedImageUrl;
                                if (newImage != null) {
                                  final supabase =
                                      ref.read(supabaseClientProvider);
                                  final uid = ref.read(currentUserIdProvider);
                                  final ts = DateTime.now()
                                      .millisecondsSinceEpoch;
                                  final storagePath =
                                      'listings/$uid/listing_$ts.jpg';
                                  final bytes = await newImage!.readAsBytes();
                                  await supabase.storage
                                      .from('listing-images')
                                      .uploadBinary(storagePath, bytes,
                                          fileOptions: const FileOptions(
                                              contentType: 'image/jpeg',
                                              upsert: true));
                                  uploadedImageUrl =
                                      '${supabase.storage.from('listing-images').getPublicUrl(storagePath)}?t=$ts';
                                }

                                final payload = <String, dynamic>{
                                  'title': titleCtrl.text.trim(),
                                  'description': descCtrl.text.trim(),
                                  'split_amount': splitAmt,
                                  'total_cost': splitAmt * slots,
                                  'amount': splitAmt * slots,
                                  'slots_total': slots,
                                  'split_ways': slots,
                                  'status': isActive ? 'active' : 'paused',
                                }; // ignore: use_null_aware_elements
                                if (uploadedImageUrl != null) {
                                  payload['image_url'] = uploadedImageUrl;
                                }
                                await ref
                                    .read(listingsNotifierProvider.notifier)
                                    .updateListing(listing.id, payload);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setSheetState(() => isSaving = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
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
                              'Save Changes',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
    ).whenComplete(() {
      // Delay by one frame so any pending rebuild triggered by provider
      // invalidation finishes before the controllers are torn down.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleCtrl.dispose();
        descCtrl.dispose();
        splitAmountCtrl.dispose();
        slotsCtrl.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingByIdProvider(widget.listingId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.scaffoldBg(context),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load listing: $e',
            style: const TextStyle(fontFamily: 'Inter'),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return const Center(
                child: Text('Listing not found.',
                    style: TextStyle(fontFamily: 'Inter')));
          }

          return CustomScrollView(
            slivers: [
              // ── Sticky top app bar ─────────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                expandedHeight: 0,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor:
                    isDark ? const Color(0xFF0D1B1E) : AppColors.surfaceLight,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                title: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 48,
                        height: 56,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    // Title
                    Expanded(
                      child: Text(
                        listing.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Share button
                    GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 48,
                        height: 56,
                        child: Center(
                          child: Icon(
                            Icons.share_rounded,
                            size: 22,
                            color: isDark
                                ? AppColors.textDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge + Title + Tag pills
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge: rounded-full, bg=primary/20
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x3311B4D4),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcon(listing.category),
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  listing.category.label.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title: text-3xl fontExtraBold
                          Text(
                            listing.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Location + Remote tag pills
                          Row(
                            children: [
                              _TagPill(
                                icon: Icons.public_rounded,
                                label: listing.isRemote
                                    ? 'Global'
                                    : listing.location,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _TagPill(
                                icon: listing.isRemote
                                    ? Icons.wifi_rounded
                                    : Icons.near_me_rounded,
                                label:
                                    listing.isRemote ? 'Remote' : 'In-Person',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Poster section (border-y) ──────────────────────
                    Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Row(
                        children: [
                          // Avatar with ring-2 ring-primary/20
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x3311B4D4),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: isDark
                                  ? AppColors.cardDark
                                  : AppColors.primaryLight,
                              backgroundImage:
                                  listing.posterAvatarUrl != null
                                      ? CachedNetworkImageProvider(
                                          listing.posterAvatarUrl!,
                                          cacheKey: listing.posterAvatarUrl!,
                                        )
                                      : null,
                              child: listing.posterAvatarUrl == null
                                  ? Text(
                                      listing.posterName?.isNotEmpty ==
                                              true
                                          ? listing.posterName![0]
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        fontFamily: 'Inter',
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Name + trust score
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.posterName ?? 'Unknown',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Trust Score: ${listing.posterTrustScore?.toInt() ?? 0}%',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // View Profile button: bg=primary/10 text=primary
                          GestureDetector(
                            onTap: () =>
                                context.push('/profile/${listing.userId}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0x1A11B4D4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'View Profile',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Pricing grid ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Row 1: Total Plan | Your Share
                          Row(
                            children: [
                              Expanded(
                                child: _PriceCard(
                                  label: 'TOTAL PLAN',
                                  value:
                                      '₦${_formatAmount(listing.totalCost)}',
                                  suffix:
                                      _durationSuffix(listing.duration),
                                  isDark: isDark,
                                  highlight: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PriceCard(
                                  label: 'YOUR SHARE',
                                  value:
                                      '₦${_formatAmount(listing.splitAmount)}',
                                  suffix:
                                      _durationSuffix(listing.duration),
                                  isDark: isDark,
                                  highlight: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Row 2: Availability (full width)
                          _AvailabilityCard(
                            slotsTotal: listing.slotsTotal,
                            slotsFilled: listing.slotsFilled,
                            slotsLeft: listing.slotsLeft,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // ── About this split ───────────────────────────────
                    if (listing.description?.isNotEmpty == true) ...[
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About this split',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              listing.description!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                height: 1.65,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Features ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        children: [
                          _FeatureRow(
                            title: listing.duration ==
                                    ListingDuration.monthly
                                ? 'Auto-Renew enabled'
                                : 'One-time payment',
                            subtitle: listing.duration ==
                                    ListingDuration.monthly
                                ? 'Payments are processed automatically every 30 days.'
                                : 'A single payment covers the full cost.',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          _FeatureRow(
                            title: listing.isRemote
                                ? 'Remote / Global'
                                : 'In-Person: ${listing.location}',
                            subtitle: listing.isRemote
                                ? 'No location required — join from anywhere.'
                                : 'You need to be in or near ${listing.location}.',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // ── Tags ──────────────────────────────────────────
                    if (listing.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: listing.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.cardDark
                                        : AppColors.primaryLight,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textMuted
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    // Bottom spacing so content clears the CTA bar
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // ── Sticky bottom CTA bar ──────────────────────────────────────────
      bottomNavigationBar: listingAsync.maybeWhen(
        data: (listing) {
          if (listing == null) return null;
          final isOwner = listing.userId == currentUserId;
          final slotsLeft = listing.slotsLeft;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark.withValues(alpha: 0.85)
                      : AppColors.surfaceLight.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: isOwner
                        ? SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _showEditSheet(listing),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Listing',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  (_hasRequested ||
                                          slotsLeft == 0 ||
                                          _isRequesting)
                                      ? null
                                      : () {
                                          final uid =
                                              ref.read(currentUserIdProvider);
                                          if (uid == null) {
                                            context.push('/login');
                                            return;
                                          }
                                          _showRequestDialog(listing);
                                        },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: isDark
                                    ? AppColors.borderSlate
                                    : AppColors.borderLight,
                                disabledForegroundColor: AppColors.textMuted,
                              ),
                              child: _isRequesting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _hasRequested
                                              ? 'Request Sent'
                                              : slotsLeft == 0
                                                  ? 'No Slots Available'
                                                  : 'Request to Join',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (!_hasRequested &&
                                            slotsLeft > 0) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 22),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  String _durationSuffix(ListingDuration d) {
    switch (d) {
      case ListingDuration.monthly:
        return '/mo';
      case ListingDuration.oneTime:
        return '';
      case ListingDuration.custom:
        return '/pp';
    }
  }

  IconData _categoryIcon(ListingCategory c) {
    switch (c) {
      case ListingCategory.subscription:
        return Icons.subscriptions_rounded;
      case ListingCategory.apartment:
        return Icons.home_rounded;
      case ListingCategory.carpool:
        return Icons.directions_car_rounded;
      case ListingCategory.groceries:
        return Icons.shopping_cart_rounded;
      case ListingCategory.office:
        return Icons.desktop_windows_rounded;
      case ListingCategory.bills:
        return Icons.receipt_long_rounded;
      case ListingCategory.other:
        return Icons.category_rounded;
    }
  }
}

// ── _TagPill ────────────────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _TagPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark
                ? AppColors.textMuted
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _PriceCard ───────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final bool isDark;
  final bool highlight;

  const _PriceCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.isDark,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight
        ? const Color(0x0D11B4D4) // primary/5
        : isDark
            ? const Color(0x801E293B) // slate-800/50
            : AppColors.surfaceLight;
    final borderColor = highlight
        ? const Color(0x6611B4D4) // primary/40
        : isDark
            ? AppColors.borderSlate
            : AppColors.borderLight;
    final labelColor = highlight
        ? AppColors.primary
        : isDark
            ? AppColors.textMuted
            : AppColors.textSecondary;
    final valueColor = highlight
        ? AppColors.primary
        : isDark
            ? AppColors.textDark
            : AppColors.textPrimary;
    final suffixColor = highlight
        ? AppColors.primary.withValues(alpha: 0.65)
        : isDark
            ? AppColors.textMuted
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
              children: [
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: suffixColor,
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

// ── _AvailabilityCard ────────────────────────────────────────────────────────

class _AvailabilityCard extends StatelessWidget {
  final int slotsTotal;
  final int slotsFilled;
  final int slotsLeft;
  final bool isDark;

  const _AvailabilityCard({
    required this.slotsTotal,
    required this.slotsFilled,
    required this.slotsLeft,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0x801E293B) // slate-800/50
        : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderSlate : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textDark : AppColors.textPrimary;
    final labelColor =
        isDark ? AppColors.textMuted : AppColors.textSecondary;
    final borderBackColor =
        isDark ? const Color(0xFF0D1B1E) : Colors.white;

    // Stacked avatars: show up to 2 filled circles, then "+N" overflow chip
    final showCount = slotsFilled.clamp(0, 2);
    final overflow = slotsFilled - showCount;
    final int totalItems = showCount + (overflow > 0 ? 1 : 0);
    final double stackWidth = totalItems > 0
        ? (totalItems - 1) * 16.0 + 26.0
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABILITY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$slotsLeft/$slotsTotal Slots Left',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              // Stacked mini avatar circles
              if (slotsFilled > 0)
                SizedBox(
                  width: stackWidth,
                  height: 26,
                  child: Stack(
                    children: [
                      for (int i = 0; i < showCount; i++)
                        Positioned(
                          left: i * 16.0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFF374151),
                              border: Border.all(
                                color: borderBackColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      if (overflow > 0)
                        Positioned(
                          left: showCount * 16.0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              border: Border.all(
                                color: borderBackColor,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+$overflow',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _FeatureRow ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _FeatureRow({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── _EditField ────────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final int minLines;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    required this.isDark,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textPrimary;
    final fillColor =
        isDark ? const Color(0xFF1A2B2E) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white10 : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: textColor,
          ),
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
