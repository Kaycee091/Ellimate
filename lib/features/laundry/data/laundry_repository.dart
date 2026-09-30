import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/laundry_booking.dart';

class LaundryRepository {
  LaundryRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<LaundryBooking>> fetchBookings({
    required String apartmentId,
    DateTime? date,
  }) async {
    try {
      var query = _supabase
          .from('laundry_bookings')
          .select('*, profiles(id, name, avatar_url)')
          .eq('apartment_id', apartmentId);

      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        query = query.eq('booking_date', dateStr);
      } else {
        // Fetch today and future
        final today = DateTime.now().toIso8601String().split('T')[0];
        query = query.gte('booking_date', today);
      }

      final data = await query
          .neq('status', 'cancelled')
          .order('booking_date')
          .order('start_time');

      return (data as List).map((b) {
        final profileData = b['profiles'];
        final booking = LaundryBooking.fromJson({
          ...b,
          'booking_date': b['booking_date'],
        });
        if (profileData != null) {
          return booking.copyWith(
            userName: profileData['name'],
            userAvatarUrl: profileData['avatar_url'],
          );
        }
        return booking;
      }).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to load laundry schedule.',
        originalError: e,
      );
    }
  }

  Future<List<String>> fetchBookedSlots({
    required String apartmentId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final data = await _supabase
          .from('laundry_bookings')
          .select('start_time')
          .eq('apartment_id', apartmentId)
          .eq('booking_date', dateStr)
          .neq('status', 'cancelled');

      return (data as List).map((b) => b['start_time'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<LaundryBooking> createBooking({
    required String apartmentId,
    required String userId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Use RPC for atomic booking with conflict detection
      final data = await _supabase.rpc('book_laundry_slot', params: {
        'p_apartment_id': apartmentId,
        'p_user_id': userId,
        'p_booking_date': bookingDate.toIso8601String().split('T')[0],
        'p_start_time': startTime,
        'p_end_time': endTime,
      });

      if (data == null) {
        throw const ConflictException(
          message: 'This laundry slot is no longer available.',
        );
      }

      return LaundryBooking.fromJson(data as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') ||
          msg.contains('duplicate') ||
          msg.contains('conflict') ||
          msg.contains('slot_taken') ||
          msg.contains('exclusion')) {
        throw const ConflictException(
          message: 'This laundry slot is no longer available.',
        );
      }
      throw DatabaseException(
        message: 'Unable to book laundry slot. Please try again.',
        originalError: e,
      );
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase.from('laundry_bookings').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to cancel booking.',
        originalError: e,
      );
    }
  }

  Future<LaundryBooking?> fetchCurrentBooking(String apartmentId) async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final data = await _supabase
          .from('laundry_bookings')
          .select('*, profiles(id, name, avatar_url)')
          .eq('apartment_id', apartmentId)
          .eq('booking_date', today)
          .lte('start_time', timeStr)
          .gte('end_time', timeStr)
          .eq('status', 'upcoming')
          .maybeSingle();

      if (data == null) return null;
      final profileData = data['profiles'];
      final booking = LaundryBooking.fromJson(data);
      if (profileData != null) {
        return booking.copyWith(
          userName: profileData['name'],
          userAvatarUrl: profileData['avatar_url'],
        );
      }
      return booking;
    } catch (e) {
      return null;
    }
  }
}
