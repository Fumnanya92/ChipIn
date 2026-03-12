import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/listings/presentation/providers/listings_provider.dart';
import 'package:chipin/features/home/presentation/pages/home_screen.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  String _sortBy = 'newest';

  static const _categories = [
    ('subscription', 'Subs'),
    ('apartment', 'Housing'),
    ('carpool', 'Travel'),
    ('groceries', 'Groceries'),
    ('office', 'Work'),
    ('bills', 'Bills'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ListingModel> _filtered(List<ListingModel> all) {
    var list = all.where((l) {
      final matchesQuery = _query.isEmpty ||
          l.title.toLowerCase().contains(_query.toLowerCase()) ||
          l.category.label.toLowerCase().contains(_query.toLowerCase()) ||
          (l.description?.toLowerCase().contains(_query.toLowerCase()) ??
              false);
      final matchesCat =
          _selectedCategory == null || l.category.name == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();

    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.splitAmount.compareTo(b.splitAmount));
      case 'price_desc':
        list.sort((a, b) => b.splitAmount.compareTo(a.splitAmount));
      case 'trust':
        list.sort((a, b) =>
            (b.posterTrustScore ?? 0).compareTo(a.posterTrustScore ?? 0));
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search splits, categories…',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                for (final cat in _categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: cat.$2,
                      selected: _selectedCategory == cat.$1,
                      onTap: () => setState(() => _selectedCategory =
                          _selectedCategory == cat.$1 ? null : cat.$1),
                    ),
                  ),
              ],
            ),
          ),

          // Sort + count row
          listingsAsync.maybeWhen(
            data: (all) {
              final filtered = _filtered(all);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} split${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(
                            value: 'price_asc', child: Text('Price ↑')),
                        DropdownMenuItem(
                            value: 'price_desc', child: Text('Price ↓')),
                        DropdownMenuItem(
                            value: 'trust', child: Text('Trust Score')),
                      ],
                      onChanged: (v) =>
                          setState(() => _sortBy = v ?? 'newest'),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Listing list
          Expanded(
            child: listingsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: 5,
                itemBuilder: (_, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (all) {
                final filtered = _filtered(all);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No splits match your search.',
                      style: TextStyle(
                          fontFamily: 'Inter', color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ListingCard(
                      listing: filtered[i],
                      onTap: () =>
                          context.push('/listing/${filtered[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
