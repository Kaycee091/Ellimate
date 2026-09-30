import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/user_profile.dart';

class AuthRepository {
  AuthRepository(this._supabase);

  final supa.SupabaseClient _supabase;

  supa.User? get currentUser => _supabase.auth.currentUser;
  supa.Session? get currentSession => _supabase.auth.currentSession;

  Stream<supa.AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  Future<supa.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );

      if (response.user == null) {
        throw const AppAuthException(
          message: 'Unable to create your account. Please try again.',
        );
      }

      return response.user!;
    } on AppAuthException {
      rethrow;
    } on supa.AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('email already')) {
        throw const AppAuthException(
          message: 'An account with this email already exists.',
          code: 'email_exists',
        );
      }
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw AppAuthException(
        message: 'Unable to create your account. Please try again.',
        originalError: e,
      );
    }
  }

  Future<supa.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw const AppAuthException(
          message: 'Invalid email or password.',
          code: 'invalid_credentials',
        );
      }

      return response.user!;
    } on AppAuthException {
      rethrow;
    } on supa.AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('credentials')) {
        throw const AppAuthException(
          message: 'Invalid email or password.',
          code: 'invalid_credentials',
        );
      }
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw AppAuthException(
        message: 'Unable to log in. Please try again.',
        originalError: e,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppAuthException(
        message: 'Unable to log out. Please try again.',
        originalError: e,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on supa.AuthException catch (e) {
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw AppAuthException(
        message: 'Unable to send reset email. Please try again.',
        originalError: e,
      );
    }
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw const AppAuthException(message: 'Not authenticated.');

      // Call RPC to handle cascading deletion safely
      await _supabase.rpc('delete_user_account', params: {'uid': user.id});
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppAuthException(
        message: 'Unable to delete account. Please try again.',
        originalError: e,
      );
    }
  }
}
