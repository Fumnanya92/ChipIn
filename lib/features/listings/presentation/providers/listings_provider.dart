import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/shared/models/listing_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// All active listings (home feed)
final listingsProvider =
    FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final data = await supabase
      .from('listings')
      .select('*, users(full_name, avatar_url, trust_score)')
      .eq('status', 'active')
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List)
      .map((d) => ListingModel.fromJson(d as Map<String, dynamic>))
      .toList();
});

// Listings filtered by category
final listingsByCategoryProvider =
    FutureProvider.autoDispose.family<List<ListingModel>, String?>(
        (ref, category) async {
  final supabase = ref.read(supabaseClientProvider);
  if (category == null) {
    final data = await supabase
        .from('listings')
        .select('*, users(full_name, avatar_url, trust_score)')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((d) => ListingModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }
  final data = await supabase
      .from('listings')
      .select('*, users(full_name, avatar_url, trust_score)')
      .eq('status', 'active')
      .eq('category', category)
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List)
      .map((d) => ListingModel.fromJson(d as Map<String, dynamic>))
      .toList();
});

// Single listing by ID
final listingByIdProvider =
    FutureProvider.autoDispose.family<ListingModel?, String>((ref, id) async {
  final supabase = ref.read(supabaseClientProvider);
  final data = await supabase
      .from('listings')
      .select('*, users(full_name, avatar_url, trust_score)')
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return ListingModel.fromJson(data);
});

// Listings created by the current user
final myListingsProvider =
    FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('listings')
      .select('*, users(full_name, avatar_url, trust_score)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((d) => ListingModel.fromJson(d as Map<String, dynamic>))
      .toList();
});

class ListingsNotifier extends AsyncNotifier<List<ListingModel>> {
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);

  @override
  Future<List<ListingModel>> build() async {
    final data = await _supabase
        .from('listings')
        .select('*, users(full_name, avatar_url, trust_score)')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((d) => ListingModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<ListingModel> createListing(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final now = DateTime.now().toIso8601String();
    final row = {
      ...data,
      // Legacy column aliases kept until migration is applied to production.
      'amount': (data['total_cost'] as num?)?.toDouble() ?? 0.0,
      'split_ways': (data['slots_total'] as num?)?.toInt() ?? 2,
      'user_id': userId,
      'slots_filled': 0,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    };
    final result =
        await _supabase.from('listings').insert(row).select().single();
    final listing = ListingModel.fromJson(result);
    final current = state.value ?? [];
    state = AsyncData([listing, ...current]);
    return listing;
  }
}

final listingsNotifierProvider =
    AsyncNotifierProvider<ListingsNotifier, List<ListingModel>>(
        () => ListingsNotifier());
