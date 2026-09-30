class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.apartmentId,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.updatedAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  final String id;
  final String apartmentId;
  final String userId;
  final String message;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? senderName;
  final String? senderAvatarUrl;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      apartmentId: json['apartment_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? apartmentId,
    String? userId,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'apartment_id': apartmentId,
        'user_id': userId,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}
