import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared progress bar widget — imported by post_details_screen & post_extras_screen
// ─────────────────────────────────────────────────────────────────────────────
class PostProgressBar extends StatelessWidget {
  final int step; // 1, 2, or 3
  final String? label; // override default step label

  const PostProgressBar({super.key, required this.step, this.label});

  String get _label {
    if (label != null) return label!;
    switch (step) {
      case 1:
        return 'Pick Category';
      case 2:
        return 'Details';
      case 3:
        return 'Step 3: Extras & Publish';
      default:
        return 'Step $step';
    }
  }

  String get _stepText {
    if (step == 3) return '3/3';
    return 'Step $step of 3';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textOnColor = isDark ? AppColors.textDark : AppColors.textPrimary;
    final trackColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight;
    final fraction = step / 3.0;
    final hasGlow = step == 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textOnColor,
                ),
              ),
              Text(
                _stepText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * fraction;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Fill
                  Container(
                    width: fillWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: hasGlow
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category data model
// ─────────────────────────────────────────────────────────────────────────────
class _CatOption {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;

  const _CatOption(this.key, this.label, this.subtitle, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card widget
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final _CatOption cat;
  final bool selected;
  final VoidCallback onTap;
  final bool rowLayout; // true = Other card (horizontal)

  const _CategoryCard({
    required this.cat,
    required this.selected,
    required this.onTap,
    this.rowLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? const Color(0xFF0D1B22) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF1E293B) : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : cardBorder,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: rowLayout ? _rowContent(context) : _columnContent(context),
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(cat.icon, size: 24, color: AppColors.primary),
    );
  }

  Widget _titleText(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Text(
      cat.label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textDark : AppColors.textPrimary,
      ),
    );
  }

  Widget _subtitleText() {
    return Text(
      cat.subtitle,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _columnContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBox(),
        const SizedBox(height: 12),
        _titleText(context),
        const SizedBox(height: 3),
        _subtitleText(),
      ],
    );
  }

  Widget _rowContent(BuildContext context) {
    return Row(
      children: [
        _iconBox(),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _titleText(context),
            const SizedBox(height: 3),
            _subtitleText(),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Category Screen — Step 1 of 3
// ─────────────────────────────────────────────────────────────────────────────
class PostCategoryScreen extends StatefulWidget {
  const PostCategoryScreen({super.key});

  @override
  State<PostCategoryScreen> createState() => _PostCategoryScreenState();
}

class _PostCategoryScreenState extends State<PostCategoryScreen> {
  String? _selected;

  static const _categories = [
    _CatOption('apartment', 'Apartment', 'Rent & Utilities',
        Icons.home_rounded),
    _CatOption('subscription', 'Subscription', 'Streaming & Apps',
        Icons.subscriptions_rounded),
    _CatOption('carpool', 'Carpool', 'Shared Rides',
        Icons.directions_car_rounded),
    _CatOption('bills', 'Bills', 'Household Bills',
        Icons.receipt_long_rounded),
    _CatOption('office', 'Office', 'Shared Supplies', Icons.work_rounded),
    _CatOption('groceries', 'Groceries', 'Food & Supplies',
        Icons.shopping_cart_rounded),
  ];

  static const _other = _CatOption(
    'other',
    'Other',
    'Everything else you want to split',
    Icons.more_horiz_rounded,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final appBarBg = isDark ? const Color(0xFF121C21) : Colors.white;
    final footerBg = isDark ? const Color(0xFF121C21) : Colors.white;
    final textOnColor =
        isDark ? AppColors.textDark : AppColors.textPrimary;
    final footerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.borderLight;
    final disabledBg =
        isDark ? const Color(0xFF1E293B) : AppColors.borderLight;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textOnColor, size: 24),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => context.push(
                            '/post/details',
                            extra: {'category': _selected},
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: disabledBg,
                    disabledForegroundColor: AppColors.textMuted,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select a category to continue',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: _selected == null
                      ? AppColors.textMuted
                      : Colors.transparent,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          PostProgressBar(step: 1),

          // Heading
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            child: Column(
              children: [
                Text(
                  'What is this for?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textOnColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a category to help organize your split',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Category grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Row 1: Apartment + Subscription
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            cat: _categories[0],
                            selected: _selected == _categories[0].key,
                            onTap: () =>
                                setState(() => _selected = _categories[0].key),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CategoryCard(
                            cat: _categories[1],
                            selected: _selected == _categories[1].key,
                            onTap: () =>
                                setState(() => _selected = _categories[1].key),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Carpool + Bills
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            cat: _categories[2],
                            selected: _selected == _categories[2].key,
                            onTap: () =>
                                setState(() => _selected = _categories[2].key),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CategoryCard(
                            cat: _categories[3],
                            selected: _selected == _categories[3].key,
                            onTap: () =>
                                setState(() => _selected = _categories[3].key),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 3: Office + Groceries
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            cat: _categories[4],
                            selected: _selected == _categories[4].key,
                            onTap: () =>
                                setState(() => _selected = _categories[4].key),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CategoryCard(
                            cat: _categories[5],
                            selected: _selected == _categories[5].key,
                            onTap: () =>
                                setState(() => _selected = _categories[5].key),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Other — full width row layout
                  _CategoryCard(
                    cat: _other,
                    selected: _selected == _other.key,
                    onTap: () => setState(() => _selected = _other.key),
                    rowLayout: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
