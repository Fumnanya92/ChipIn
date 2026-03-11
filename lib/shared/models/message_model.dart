import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  // Joined
  final String? senderName;
  final String? senderAvatarUrl;

  const MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.readAt,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  bool get isRead => readAt != null;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender']?['full_name'] as String?,
      senderAvatarUrl: json['sender']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [id, matchId, senderId, content, createdAt];
}
