import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/apartment.dart';
import '../../../shared/widgets/ellimate_avatar.dart';
import '../../../shared/widgets/ellimate_states.dart';

final roommatesProvider = FutureProvider<List<ApartmentMember>>((ref) async {
  final apartment = await ref.watch(currentApartmentProvider.future);
  if (apartment == null) return [];
  return ref.read(apartmentRepositoryProvider).fetchMembers(apartment.id);
});

class RoommatesScreen extends ConsumerWidget {
  const RoommatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roommatesProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Roommates', style: AppTypography.sectionHeading),
      ),
      body: membersAsync.when(
        loading: () => const ElliMateLoading(),
        error: (e, _) => ElliMateErrorState(
          message: 'Unable to load roommates.',
          onRetry: () => ref.invalidate(roommatesProvider),
        ),
        data: (members) => RefreshIndicator(
          color: AppColors.primaryCoral,
          onRefresh: () async => ref.invalidate(roommatesProvider),
          child: members.isEmpty
              ? const ElliMateEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: "You're the only one here",
                  subtitle: 'Share your invite code to add roommates.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _RoommateCard(member: members[i]),
                ),
        ),
      ),
    );
  }
}

class _RoommateCard extends StatelessWidget {
  const _RoommateCard({required this.member});
  final ApartmentMember member;

  @override
  Widget build(BuildContext context) {
    final name = member.profile?.name ?? 'Unknown';
    final role = member.role == 'admin' ? 'Admin' : 'Member';
    final isAdmin = member.role == 'admin';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ElliMateAvatar(
            imageUrl: member.profile?.avatarUrl,
            name: name,
            radius: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodySemiBold),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primaryCoral.withValues(alpha: 0.12)
                            : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role,
                        style: AppTypography.caption.copyWith(
                          color: isAdmin
                              ? AppColors.primaryCoral
                              : AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.secondaryText),
        ],
      ),
    );
  }
}
