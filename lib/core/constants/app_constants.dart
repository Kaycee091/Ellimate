class AppConstants {
  AppConstants._();

  static const String appName = 'ElliMate';
  static const String appTagline = 'Live together. Communicate better.';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zkrhigrtyyxfqkpqblfh.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // Storage buckets
  static const String profileImagesBucket = 'profile-images';

  // Invite code length
  static const int inviteCodeLength = 6;

  // Chat pagination
  static const int chatPageSize = 50;
  static const int updatesPageSize = 20;

  // Laundry slot duration (hours)
  static const int laundrySlotDurationHours = 1;

  // Time slots (24-hour format start hours)
  static const List<int> laundryTimeSlots = [
    6, 7, 8, 9, 10, 11, 12,
    13, 14, 15, 16, 17, 18,
    19, 20, 21, 22,
  ];

  // Notification channels
  static const String chatNotificationChannelId = 'chat_channel';
  static const String laundryNotificationChannelId = 'laundry_channel';
  static const String updateNotificationChannelId = 'update_channel';

  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Unable to connect. Please check your internet connection.';
  static const String sessionExpiredError = 'Your session has expired. Please log in again.';
}
