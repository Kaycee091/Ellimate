import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/apartment_update.dart';
import '../../../shared/widgets/ellimate_states.dart';

final updatesProvider = FutureProvider<List<ApartmentUpdate>>((ref) async {
  final apartment = await ref.watch(currentApartmentProvider.future);
  if (apartment == null) return [];
  return ref.read(updatesRepositoryProvider).fetchUpdates(
    apartmentId: apartment.id,
  );
});

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(updatesProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Apartment Updates', style: AppTypography.screenHeading),
            ),

            Expanded(
              child: updatesAsync.when(
                loading: () => const ElliMateLoading(),
                error: (e, _) => ElliMateErrorState(
                  message: 'Unable to load updates.',
                  onRetry: () => ref.invalidate(updatesProvider),
                ),
                data: (updates) => RefreshIndicator(
                  color: AppColors.primaryCoral,
                  onRefresh: () async => ref.invalidate(updatesProvider),
                  child: updates.isEmpty
                      ? ElliMateEmptyState(
                          icon: Icons.campaign_rounded,
                          title: 'No apartment updates yet',
                          subtitle: isAdmin
                              ? 'Post the first update for your roommates.'
                              : 'Your admin will post updates here.',
                          actionLabel: isAdmin ? 'New Update' : null,
                          onAction: isAdmin
                              ? () => context.push('/updates/create')
                              : null,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                          itemCount: updates.length,
                          itemBuilder: (context, i) =>
                              _UpdateCard(update: updates[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/updates/create'),
              backgroundColor: AppColors.primaryCoral,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'New Update',
                style: AppTypography.bodySemiBold.copyWith(color: AppColors.white),
              ),
            )
          : null,
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.update});
  final ApartmentUpdate update;

  Color get _categoryColor {
    switch (update.category) {
      case UpdateCategory.maintenance:
        return AppColors.warning;
      case UpdateCategory.water:
        return AppColors.blue;
      case UpdateCategory.electricity:
        return AppColors.purple;
      case UpdateCategory.cleaning:
        return AppColors.success;
      case UpdateCategory.security:
        return AppColors.error;
      case UpdateCategory.parcel:
        return AppColors.primaryCoral;
      default:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                update.category.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(update.title, style: AppTypography.bodySemiBold),
                    ),
                    Text(
                      DateTimeUtils.formatRelative(update.createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  update.description,
                  style: AppTypography.small,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (update.scheduledAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeUtils.formatFullDate(update.scheduledAt!),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    update.category.displayName,
                    style: AppTypography.caption.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
