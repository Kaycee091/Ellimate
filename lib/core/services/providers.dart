import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/apartment/data/apartment_repository.dart';
import '../../features/laundry/data/laundry_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/updates/data/updates_repository.dart';
import '../../features/profile/data/profile_repository.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final apartmentRepositoryProvider = Provider<ApartmentRepository>((ref) {
  return ApartmentRepository(ref.watch(supabaseClientProvider));
});

final laundryRepositoryProvider = Provider<LaundryRepository>((ref) {
  return LaundryRepository(ref.watch(supabaseClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

final updatesRepositoryProvider = Provider<UpdatesRepository>((ref) {
  return UpdatesRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});
