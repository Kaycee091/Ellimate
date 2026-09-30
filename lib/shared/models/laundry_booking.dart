enum BookingStatus {
  upcoming,
  current,
  completed,
  cancelled;

  static BookingStatus fromString(String value) {
    switch (value) {
      case 'current':
        return BookingStatus.current;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.upcoming;
    }
  }

  String get value {
    switch (this) {
      case BookingStatus.upcoming:
        return 'upcoming';
      case BookingStatus.current:
        return 'current';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }
}

class LaundryBooking {
  const LaundryBooking({
    required this.id,
    required this.apartmentId,
    required this.userId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  final String id;
  final String apartmentId;
  final String userId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatarUrl;

  factory LaundryBooking.fromJson(Map<String, dynamic> json) {
    // booking_date can be "2025-09-30" or a full ISO string
    final dateRaw = json['booking_date'] as String;
    final DateTime parsedDate = dateRaw.length == 10
        ? DateTime.parse('${dateRaw}T00:00:00')
        : DateTime.parse(dateRaw);

    // Handle updated_at being nullable
    final updatedRaw = json['updated_at'] as String?;
    final DateTime updatedAt = updatedRaw != null
        ? DateTime.parse(updatedRaw)
        : DateTime.parse(json['created_at'] as String);

    return LaundryBooking(
      id: json['id'] as String,
      apartmentId: json['apartment_id'] as String,
      userId: json['user_id'] as String,
      bookingDate: parsedDate,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: BookingStatus.fromString(json['status'] as String? ?? 'upcoming'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: updatedAt,
    );
  }

  LaundryBooking copyWith({
    String? id,
    String? apartmentId,
    String? userId,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
  }) {
    return LaundryBooking(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      userId: userId ?? this.userId,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  String get timeRange => '$startTime - $endTime';
}
