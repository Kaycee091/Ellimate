import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/apartment_update.dart';

class UpdatesRepository {
  UpdatesRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ApartmentUpdate>> fetchUpdates({
    required String apartmentId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase
          .from('apartment_updates')
          .select('*, profiles(id, name, avatar_url)')
          .eq('apartment_id', apartmentId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((u) {
        final profileData = u['profiles'];
        final update = ApartmentUpdate.fromJson(u);
        if (profileData != null) {
          return update.copyWith(
            creatorName: profileData['name'],
            creatorAvatarUrl: profileData['avatar_url'],
          );
        }
        return update;
      }).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to load updates.',
        originalError: e,
      );
    }
  }

  Future<ApartmentUpdate> createUpdate({
    required String apartmentId,
    required String userId,
    required String title,
    required String description,
    required UpdateCategory category,
    DateTime? scheduledAt,
  }) async {
    try {
      final data = await _supabase
          .from('apartment_updates')
          .insert({
            'apartment_id': apartmentId,
            'created_by': userId,
            'title': title.trim(),
            'description': description.trim(),
            'category': category.name,
            'scheduled_at': scheduledAt?.toIso8601String(),
          })
          .select()
          .single();

      return ApartmentUpdate.fromJson(data);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to publish update. Please try again.',
        originalError: e,
      );
    }
  }

  Future<void> deleteUpdate(String updateId) async {
    try {
      await _supabase.from('apartment_updates').delete().eq('id', updateId);
    } catch (e) {
      throw DatabaseException(message: 'Unable to delete update.');
    }
  }
}
