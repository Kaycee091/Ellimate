import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/invite_code_generator.dart';
import '../../../shared/models/apartment.dart';

class ApartmentRepository {
  ApartmentRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Apartment> createApartment({
    required String name,
    String? description,
    required String userId,
  }) async {
    try {
      // Generate unique invite code
      String inviteCode;
      bool codeUnique = false;
      int attempts = 0;

      do {
        inviteCode = InviteCodeGenerator.generate();
        final existing = await _supabase
            .from('apartments')
            .select('id')
            .eq('invite_code', inviteCode)
            .maybeSingle();
        codeUnique = existing == null;
        attempts++;
      } while (!codeUnique && attempts < 10);

      if (!codeUnique) {
        throw const DatabaseException(
          message: 'Unable to generate unique invite code. Please try again.',
        );
      }

      // Use RPC for atomic creation
      final data = await _supabase.rpc('create_apartment_with_admin', params: {
        'p_name': name.trim(),
        'p_description': description?.trim(),
        'p_invite_code': inviteCode,
        'p_user_id': userId,
      });

      if (data == null) {
        throw const DatabaseException(
          message: 'Unable to create apartment. Please try again.',
        );
      }

      return Apartment.fromJson(data as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to create apartment. Please try again.',
        originalError: e,
      );
    }
  }

  Future<Apartment> joinApartment({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      final code = inviteCode.trim().toUpperCase();

      // Find apartment
      final apartmentData = await _supabase
          .from('apartments')
          .select()
          .eq('invite_code', code)
          .maybeSingle();

      if (apartmentData == null) {
        throw const NotFoundException(
          message: 'This invite code is invalid.',
        );
      }

      final apartment = Apartment.fromJson(apartmentData);

      // Check if already a member
      final existing = await _supabase
          .from('apartment_members')
          .select('id')
          .eq('apartment_id', apartment.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw const ConflictException(
          message: 'You are already a member of this apartment.',
        );
      }

      // Create membership
      await _supabase.from('apartment_members').insert({
        'apartment_id': apartment.id,
        'user_id': userId,
        'role': 'member',
      });

      return apartment;
    } on AppException {
      rethrow;
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to join apartment. Please try again.',
        originalError: e,
      );
    }
  }

  Future<Apartment?> fetchCurrentApartment(String userId) async {
    try {
      final data = await _supabase
          .from('apartment_members')
          .select('apartments(*)')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      final apartmentData = data['apartments'];
      if (apartmentData == null) return null;
      return Apartment.fromJson(apartmentData as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<ApartmentMember?> fetchCurrentMembership(String userId) async {
    try {
      final data = await _supabase
          .from('apartment_members')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ApartmentMember.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<ApartmentMember>> fetchMembers(String apartmentId) async {
    try {
      final data = await _supabase
          .from('apartment_members')
          .select('*, profiles(id, name, avatar_url, email)')
          .eq('apartment_id', apartmentId)
          .order('joined_at');

      return (data as List).map((m) {
        final profileData = m['profiles'];
        final member = ApartmentMember.fromJson(m);
        if (profileData != null) {
          return member.copyWith(
            profile: UserProfileSummary.fromJson(
              profileData as Map<String, dynamic>,
            ),
          );
        }
        return member;
      }).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to load members.',
        originalError: e,
      );
    }
  }

  Future<void> updateApartment({
    required String apartmentId,
    required String name,
    String? description,
  }) async {
    try {
      await _supabase.from('apartments').update({
        'name': name.trim(),
        'description': description?.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', apartmentId);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to update apartment. Please try again.',
        originalError: e,
      );
    }
  }

  Future<void> removeMember({
    required String apartmentId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('apartment_members')
          .delete()
          .eq('apartment_id', apartmentId)
          .eq('user_id', userId);
    } catch (e) {
      throw DatabaseException(
        message: 'Unable to remove member.',
        originalError: e,
      );
    }
  }
}
