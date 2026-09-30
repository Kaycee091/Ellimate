class NotificationPreference {
  const NotificationPreference({
    required this.id,
    required this.userId,
    required this.laundryReminders,
    required this.chatMessages,
    required this.apartmentUpdates,
    required this.bookingConfirmations,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final bool laundryReminders;
  final bool chatMessages;
  final bool apartmentUpdates;
  final bool bookingConfirmations;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      laundryReminders: (json['laundry_reminders'] as bool?) ?? true,
      chatMessages: (json['chat_messages'] as bool?) ?? true,
      apartmentUpdates: (json['apartment_updates'] as bool?) ?? true,
      bookingConfirmations: (json['booking_confirmations'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory NotificationPreference.defaults(String userId) {
    final now = DateTime.now();
    return NotificationPreference(
      id: '',
      userId: userId,
      laundryReminders: true,
      chatMessages: true,
      apartmentUpdates: true,
      bookingConfirmations: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  NotificationPreference copyWith({
    String? id,
    String? userId,
    bool? laundryReminders,
    bool? chatMessages,
    bool? apartmentUpdates,
    bool? bookingConfirmations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      laundryReminders: laundryReminders ?? this.laundryReminders,
      chatMessages: chatMessages ?? this.chatMessages,
      apartmentUpdates: apartmentUpdates ?? this.apartmentUpdates,
      bookingConfirmations: bookingConfirmations ?? this.bookingConfirmations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: (json['type'] as String?) ?? 'general',
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
