import 'package:chipin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostCategoryScreen extends StatefulWidget {
  const PostCategoryScreen({super.key});

  @override
  State<PostCategoryScreen> createState() => _PostCategoryScreenState();
}

class _PostCategoryScreenState extends State<PostCategoryScreen> {
  String? _selected;

  static const _categories = [
    _CatOption('apartment', 'Apartment', 'Rent & Utilities',
        Icons.home_rounded, AppColors.catHousing, AppColors.catHousingBg),
    _CatOption('subscription', 'Subscription', 'Streaming & Apps',
        Icons.subscriptions_rounded, AppColors.catSubscription, AppColors.catSubscriptionBg),
    _CatOption('carpool', 'Carpool', 'Shared Rides',
        Icons.directions_car_rounded, AppColors.catTravel, AppColors.catTravelBg),
    _CatOption('bills', 'Bills', 'Household Bills',
        Icons.receipt_long_rounded, AppColors.catBills, AppColors.catBills),
    _CatOption('office', 'Office', 'Shared Supplies',
        Icons.desktop_windows_rounded, AppColors.catWork, AppColors.catWorkBg),
    _CatOption('groceries', 'Groceries', 'Food & Supplies',
        Icons.shopping_cart_rounded, AppColors.catGroceries, AppColors.catGroceriesBg),
    _CatOption('other', 'Other', 'Everything else',
        Icons.more_horiz_rounded, AppColors.catOther, AppColors.catOtherBg),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post a Split'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          PostProgressBar(step: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick Category',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What is this for? Select a category to organise your split.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Category grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final sel = _selected == cat.key;
                return GestureDetector(
                  onTap: () => setState(() => _selected = cat.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel ? cat.color.withValues(alpha: 0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? cat.color : AppColors.borderLight,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.icon, size: 26, color: cat.color),
                        const SizedBox(height: 8),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel ? cat.color : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          cat.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () => context.push('/post/details',
                      extra: {'category': _selected}),
              child: const Text('Next'),
            ),
          ),
          if (_selected == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(
                  'Select a category to continue',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatOption {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _CatOption(
      this.key, this.label, this.subtitle, this.icon, this.color, this.bgColor);
}

class PostProgressBar extends StatelessWidget {
  final int step; // 1, 2, or 3
  const PostProgressBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step $step of 3',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / 3,
              backgroundColor: AppColors.borderLight,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
