import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chipin/shared/models/user_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Stream of the raw Supabase User (null = logged out)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange.map(
        (event) => event.session?.user,
      );
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser?.id;
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);

  @override
  Future<UserModel?> build() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    return _fetchProfile(userId);
  }

  Future<UserModel?> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data == null ? null : UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = const AsyncLoading();
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (res.user != null) {
        final now = DateTime.now().toIso8601String();
        await _supabase.from('users').upsert({
          'id': res.user!.id,
          'email': email,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'trust_score': 0,
          'phone_verified': false,
          'id_verified': false,
          'payment_verified': false,
          'total_splits': 0,
          'average_rating': 0,
          'created_at': now,
          'updated_at': now,
        });
        state = AsyncData(await _fetchProfile(res.user!.id));
      }
    } on AuthException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        state = AsyncData(await _fetchProfile(res.user!.id));
      }
    } on AuthException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
      rethrow;
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncData(null);
  }

  Future<void> markPhoneVerified() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final current = state.value;
    final newScore = (current?.trustScore ?? 0) + 20;
    await _supabase.from('users').update({
      'phone_verified': true,
      'trust_score': newScore,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
    state = AsyncData(await _fetchProfile(userId));
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(() => AuthNotifier());
