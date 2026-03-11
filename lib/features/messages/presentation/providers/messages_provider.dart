import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/shared/models/message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Real-time stream of messages for a given match
final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, matchId) {
  final supabase = ref.read(supabaseClientProvider);
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('match_id', matchId)
      .order('created_at')
      .map((data) => data
          .map((d) => MessageModel.fromJson(d))
          .toList());
});

class MessagesNotifier extends Notifier<void> {
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);

  @override
  void build() {}

  Future<void> sendMessage(String matchId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    await _supabase.from('messages').insert({
      'match_id': matchId,
      'sender_id': userId,
      'content': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markRead(String matchId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('match_id', matchId)
        .neq('sender_id', userId)
        .isFilter('read_at', null);
  }
}

final messagesNotifierProvider =
    NotifierProvider<MessagesNotifier, void>(() => MessagesNotifier());
