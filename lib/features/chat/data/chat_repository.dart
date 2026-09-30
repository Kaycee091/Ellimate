import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/chat_message.dart';

class ChatRepository {
  ChatRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ChatMessage>> fetchMessages({
    required String apartmentId,
    int limit = 50,
    String? beforeId,
  }) async {
    try {
      var query = _supabase
          .from('chat_messages')
          .select('*, profiles(id, name, avatar_url)')
          .eq('apartment_id', apartmentId);

      if (beforeId != null) {
        // For pagination - load older messages
        final pivotData = await _supabase
            .from('chat_messages')
            .select('created_at')
            .eq('id', beforeId)
            .maybeSingle();
        if (pivotData != null) {
          query = query.lt('created_at', pivotData['created_at']);
        }
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = (data as List).map((m) {
        final profileData = m['profiles'];
        final msg = ChatMessage.fromJson(m);
        if (profileData != null) {
          return msg.copyWith(
            senderName: profileData['name'],
            senderAvatarUrl: profileData['avatar_url'],
          );
        }
        return msg;
      }).toList();

      return messages.reversed.toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to load messages.',
        originalError: e,
      );
    }
  }

  Future<ChatMessage> sendMessage({
    required String apartmentId,
    required String userId,
    required String message,
  }) async {
    try {
      final data = await _supabase
          .from('chat_messages')
          .insert({
            'apartment_id': apartmentId,
            'user_id': userId,
            'message': message.trim(),
          })
          .select()
          .single();

      return ChatMessage.fromJson(data);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to send message. Please try again.',
        originalError: e,
      );
    }
  }

  RealtimeChannel subscribeToMessages({
    required String apartmentId,
    required void Function(ChatMessage message) onMessage,
  }) {
    return _supabase
        .channel('chat:$apartmentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'apartment_id',
            value: apartmentId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final msg = ChatMessage.fromJson(payload.newRecord);
              onMessage(msg);
            }
          },
        )
        .subscribe();
  }
}
