import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/notification_preference.dart';

class ProfileRepository {
  ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<UserProfile> updateProfile({
    required String userId,
    required String name,
  }) async {
    try {
      final data = await _supabase
          .from('profiles')
          .update({
            'name': name.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(data);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to update profile. Please try again.',
        originalError: e,
      );
    }
  }

  Future<String> uploadProfileImage({
    required String userId,
    required XFile image,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final path = '$userId/avatar.$ext';

      await _supabase.storage
          .from('profile-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final url = _supabase.storage
          .from('profile-images')
          .getPublicUrl(path);

      // Update profile with new avatar URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': url,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return url;
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to upload profile image. Please try again.',
        originalError: e,
      );
    }
  }

  Future<NotificationPreference?> fetchNotificationPreferences(
    String userId,
  ) async {
    try {
      final data = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return NotificationPreference.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<NotificationPreference> updateNotificationPreferences({
    required String userId,
    required bool laundryReminders,
    required bool chatMessages,
    required bool apartmentUpdates,
    required bool bookingConfirmations,
  }) async {
    try {
      final existing = await _supabase
          .from('notification_preferences')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      final updateData = {
        'user_id': userId,
        'laundry_reminders': laundryReminders,
        'chat_messages': chatMessages,
        'apartment_updates': apartmentUpdates,
        'booking_confirmations': bookingConfirmations,
        'updated_at': DateTime.now().toIso8601String(),
      };

      Map<String, dynamic> data;
      if (existing != null) {
        data = await _supabase
            .from('notification_preferences')
            .update(updateData)
            .eq('user_id', userId)
            .select()
            .single();
      } else {
        data = await _supabase
            .from('notification_preferences')
            .insert(updateData)
            .select()
            .single();
      }

      return NotificationPreference.fromJson(data);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to save notification preferences.',
        originalError: e,
      );
    }
  }

  Future<void> saveDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    try {
      await _supabase.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');
    } catch (e) {
      // Non-critical - don't throw
    }
  }

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
