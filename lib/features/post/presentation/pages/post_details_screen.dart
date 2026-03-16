import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/post/presentation/pages/post_category_screen.dart'
    show PostProgressBar;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class PostDetailsScreen extends StatefulWidget {
  final String? category;
  const PostDetailsScreen({super.key, this.category});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _totalCostCtrl = TextEditingController();

  bool _isRemote = true;
  int _slots = 4;

  @override
  void initState() {
    super.initState();
    _locationCtrl.text = 'Global / Online';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _totalCostCtrl.dispose();
    super.dispose();
  }

  // ── Computed ───────────────────────────────────────────────────────────────
  double get _perPersonShare {
    final total = double.tryParse(_totalCostCtrl.text.trim()) ?? 0;
    if (_slots <= 0) return 0;
    return total / _slots;
  }

  bool get _canContinue {
    final total = double.tryParse(_totalCostCtrl.text.trim()) ?? 0;
    return _titleCtrl.text.trim().isNotEmpty && total > 0;
  }

  String _fmtAmt(double v) {
    if (v == 0) return '0.00';
    if (v == v.truncateToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(2);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────
  void _onRemoteToggle(bool value) {
    setState(() {
      _isRemote = value;
      _locationCtrl.text = value ? 'Global / Online' : '';
    });
  }

  void _continue() {
    final title = _titleCtrl.text.trim();
    final totalStr = _totalCostCtrl.text.trim();
    final total = double.tryParse(totalStr);

    if (title.isEmpty) {
      _showSnack('Please enter a split title');
      return;
    }
    if (total == null || total <= 0) {
      _showSnack('Please enter a valid total cost');
      return;
    }
    final location =
        _isRemote ? 'Global / Online' : _locationCtrl.text.trim();
    if (!_isRemote && location.isEmpty) {
      _showSnack('Please enter a location');
      return;
    }

    final data = {
      'category': widget.category ?? 'other',
      'title': title,
      'location': location,
      'is_remote': _isRemote,
      'total_cost': total,
      'split_amount': total / _slots,
      'slots_total': _slots,
      'duration': 'monthly',
    };
    context.push('/post/extras', extra: data);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _fieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textOnColor =
        isDark ? AppColors.textDark : AppColors.textPrimary;
    final appBarBg =
        isDark ? AppColors.backgroundDark : Colors.white;
    final footerBg =
        isDark ? AppColors.backgroundDark : Colors.white;
    final footerBorderColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.borderLight;
    final inputBg =
        isDark ? AppColors.inputDark : const Color(0xFFF1F5F9);
    final inputBorder =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textOnColor, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post a Split',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textOnColor,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: footerBg,
            border: Border(
              top: BorderSide(color: footerBorderColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              // Back button
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textSubtle
                          : AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Continue button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canContinue ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : AppColors.borderLight,
                      disabledForegroundColor: AppColors.textMuted,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Progress bar — glow effect on step 2
          PostProgressBar(step: 2),
          const SizedBox(height: 24),

          // ── Split Title ──────────────────────────────────────────────────
          _fieldLabel('Split Title'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: textOnColor,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Netflix Premium Subscription',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // ── Location ─────────────────────────────────────────────────────
          Row(
            children: [
              _fieldLabel('Location'),
              const Spacer(),
              Text(
                'Remote / Global',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: _isRemote,
                onChanged: _onRemoteToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor:
                    isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationCtrl,
            readOnly: _isRemote,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: _isRemote
                  ? AppColors.textMuted
                  : textOnColor,
            ),
            decoration: InputDecoration(
              hintText: _isRemote ? '' : 'City, Country or Venue',
              prefixIcon: Icon(
                Icons.location_on_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // ── Total Cost + Available Slots (side by side) ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Cost
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Total Cost'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _totalCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textOnColor,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₦  ',
                        prefixStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Available Slots
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Slots'),
                    const SizedBox(height: 8),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: inputBorder),
                      ),
                      child: Row(
                        children: [
                          // Minus
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_slots > 2) {
                                  setState(() => _slots--);
                                }
                              },
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 20,
                                  color: _slots > 2
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          // Count
                          SizedBox(
                            width: 36,
                            child: Text(
                              '$_slots',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textOnColor,
                              ),
                            ),
                          ),
                          // Plus
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_slots < 20) {
                                  setState(() => _slots++);
                                }
                              },
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: _slots < 20
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Your Share card ───────────────────────────────────────────────
          _YourShareCard(
            perPersonShare: _perPersonShare,
            slots: _slots,
            isDark: isDark,
            fmtAmt: _fmtAmt,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Your Share" calculation card
// ─────────────────────────────────────────────────────────────────────────────
class _YourShareCard extends StatelessWidget {
  final double perPersonShare;
  final int slots;
  final bool isDark;
  final String Function(double) fmtAmt;

  const _YourShareCard({
    required this.perPersonShare,
    required this.slots,
    required this.isDark,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    final textOnColor = isDark ? AppColors.textDark : AppColors.textPrimary;
    final othersCount = slots - 1;
    final infoText = othersCount > 0
        ? 'Cost is split equally between you and '
            '$othersCount other${othersCount == 1 ? '' : 's'}.'
        : 'Cost split equally across all slots.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: label + amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR SHARE',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₦${fmtAmt(perPersonShare)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: textOnColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ person',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right: calculator icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.primary.withValues(alpha: 0.2),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  infoText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
