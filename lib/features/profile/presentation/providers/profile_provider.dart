import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/shared/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// View any user's profile — pass 'me' to get current user's profile
final userProfileProvider =
    FutureProvider.autoDispose.family<UserModel?, String>((ref, userId) async {
  final supabase = ref.read(supabaseClientProvider);
  final effectiveId =
      userId == 'me' ? supabase.auth.currentUser?.id : userId;
  if (effectiveId == null) return null;
  final data = await supabase
      .from('users')
      .select()
      .eq('id', effectiveId)
      .maybeSingle();
  if (data == null) return null;
  return UserModel.fromJson(data);
});

class ProfileNotifier extends AsyncNotifier<UserModel?> {
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);

  @override
  Future<UserModel?> build() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? location,
    String? avatarUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (location != null) updates['location'] = location;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await _supabase.from('users').update(updates).eq('id', userId);
    ref.invalidateSelf();
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserModel?>(() => ProfileNotifier());
