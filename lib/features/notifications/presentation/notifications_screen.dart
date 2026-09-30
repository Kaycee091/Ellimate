import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/notification_preference.dart';
import '../../../shared/widgets/ellimate_states.dart';

final notificationsListProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(profileRepositoryProvider).fetchNotifications(user.id);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: AppTypography.sectionHeading),
        actions: [
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref
                    .read(profileRepositoryProvider)
                    .markAllNotificationsRead(user.id);
                ref.invalidate(notificationsListProvider);
              }
            },
            child: Text(
              'Mark all read',
              style: AppTypography.small
                  .copyWith(color: AppColors.primaryCoral),
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const ElliMateLoading(),
        error: (_, __) =>
            const ElliMateErrorState(message: 'Unable to load notifications.'),
        data: (notifications) => RefreshIndicator(
          color: AppColors.primaryCoral,
          onRefresh: () async => ref.invalidate(notificationsListProvider),
          child: notifications.isEmpty
              ? const ElliMateEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications yet',
                  subtitle: 'Your apartment notifications will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifications.length,
                  itemBuilder: (context, i) =>
                      _NotificationCard(notification: notifications[i], ref: ref),
                ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.ref});
  final AppNotification notification;
  final WidgetRef ref;

  IconData get _icon {
    switch (notification.type) {
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'laundry':
      case 'booking':
        return Icons.local_laundry_service_rounded;
      case 'update':
      case 'apartment':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'chat':
        return AppColors.blue;
      case 'laundry':
      case 'booking':
        return AppColors.primaryCoral;
      case 'update':
        return AppColors.success;
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await ref
              .read(profileRepositoryProvider)
              .markNotificationRead(notification.id);
          ref.invalidate(notificationsListProvider);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.cardSurface
              : AppColors.lightCoral.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? AppColors.lightBorder
                : AppColors.primaryCoral.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(notification.message,
                      style: AppTypography.small, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeUtils.formatRelative(notification.createdAt),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryCoral,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
