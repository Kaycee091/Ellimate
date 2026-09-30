import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/providers.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/apartment.dart';

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

// Current profile provider
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchProfile(user.id);
});

// Current membership provider
final currentMembershipProvider = FutureProvider<ApartmentMember?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(apartmentRepositoryProvider).fetchCurrentMembership(user.id);
});

// Current apartment provider
final currentApartmentProvider = FutureProvider<Apartment?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(apartmentRepositoryProvider).fetchCurrentApartment(user.id);
});

// Is admin provider
final isAdminProvider = Provider<bool>((ref) {
  final membership = ref.watch(currentMembershipProvider);
  return membership.when(
    data: (m) => m?.role == 'admin',
    loading: () => false,
    error: (_, __) => false,
  );
});
