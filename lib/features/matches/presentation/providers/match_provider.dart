import 'dart:typed_data';

import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/shared/models/match_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Matches received (I am the listing owner)
final receivedMatchesProvider =
    FutureProvider.autoDispose<List<MatchModel>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('matches')
      .select(
          '*, listings(title, image_url, split_amount), requester:users!matches_requester_id_fkey(full_name, avatar_url, trust_score)')
      .eq('owner_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((d) => MatchModel.fromJson(d as Map<String, dynamic>))
      .toList();
});

// Matches sent (I am the requester)
final sentMatchesProvider =
    FutureProvider.autoDispose<List<MatchModel>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('matches')
      .select(
          '*, listings(title, image_url, split_amount), owner:users!matches_owner_id_fkey(full_name, avatar_url, trust_score)')
      .eq('requester_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((d) => MatchModel.fromJson(d as Map<String, dynamic>))
      .toList();
});

// Single match by ID (fetches both requester + owner joined data)
final matchByIdProvider =
    FutureProvider.autoDispose.family<MatchModel?, String>((ref, matchId) async {
  final supabase = ref.read(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;
  final data = await supabase
      .from('matches')
      .select(
          '*, listings(title, image_url, split_amount), '
          'requester:users!matches_requester_id_fkey(full_name, avatar_url, trust_score), '
          'owner:users!matches_owner_id_fkey(full_name, avatar_url)')
      .eq('id', matchId)
      .maybeSingle();
  if (data == null) return null;
  return MatchModel.fromJson(data);
});

// All unread received matches count
final pendingMatchCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 0;
  final data = await supabase
      .from('matches')
      .select('id')
      .eq('owner_id', userId)
      .eq('status', 'pending');
  return (data as List).length;
});

class MatchNotifier extends AsyncNotifier<void> {
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);

  @override
  Future<void> build() async {}

  Future<void> requestToJoin(
    String listingId,
    String ownerId, {
    String? message,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final now = DateTime.now().toIso8601String();
    await _supabase.from('matches').insert({
      'listing_id': listingId,
      'requester_id': userId,
      'owner_id': ownerId,
      'status': 'pending',
      'message': message,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> acceptMatch(String matchId) async {
    await _supabase.from('matches').update({
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Accept a match and optionally set payment instructions at the same time.
  Future<void> acceptMatchWithPaymentInstructions(
    String matchId, {
    String? paymentInstructions,
  }) async {
    await _supabase.from('matches').update({
      'status': 'accepted',
      'payment_instructions': paymentInstructions,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Requester marks that they have sent payment (owner must confirm).
  Future<void> markRequesterPaid(String matchId) async {
    await _supabase.from('matches').update({
      'requester_paid_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Owner confirms they received the payment → moves match to active.
  Future<void> confirmPaymentReceived(String matchId) async {
    await _supabase.from('matches').update({
      'owner_confirmed_at': DateTime.now().toIso8601String(),
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Mark a match as completed (split finished).
  Future<void> completeSplit(String matchId) async {
    await _supabase.from('matches').update({
      'status': 'completed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Upload a payment receipt screenshot to Storage and save the URL to the match.
  Future<void> uploadReceipt(
      String matchId, Uint8List bytes, String ext) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final path = '$matchId/receipt.$ext';
    await _supabase.storage.from('payment-receipts').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
        );
    final url =
        _supabase.storage.from('payment-receipts').getPublicUrl(path);
    await _supabase.from('matches').update({
      'receipt_url': url,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  Future<void> declineMatch(String matchId) async {
    await _supabase.from('matches').update({
      'status': 'declined',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }
}

final matchNotifierProvider =
    AsyncNotifierProvider<MatchNotifier, void>(() => MatchNotifier());
