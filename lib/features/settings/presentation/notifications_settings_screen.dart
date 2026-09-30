import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/notification_preference.dart';
import '../../../shared/widgets/ellimate_states.dart';

final notifPrefsProvider =
    FutureProvider<NotificationPreference?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchNotificationPreferences(user.id);
});

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _laundryReminders = true;
  bool _chatMessages = true;
  bool _apartmentUpdates = true;
  bool _bookingConfirmations = true;
  bool _initialized = false;
  bool _isSaving = false;

  void _initFromPrefs(NotificationPreference? prefs) {
    if (prefs != null && !_initialized) {
      _laundryReminders = prefs.laundryReminders;
      _chatMessages = prefs.chatMessages;
      _apartmentUpdates = prefs.apartmentUpdates;
      _bookingConfirmations = prefs.bookingConfirmations;
      _initialized = true;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await ref.read(profileRepositoryProvider).updateNotificationPreferences(
            userId: user.id,
            laundryReminders: _laundryReminders,
            chatMessages: _chatMessages,
            apartmentUpdates: _apartmentUpdates,
            bookingConfirmations: _bookingConfirmations,
          );

      ref.invalidate(notifPrefsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification preferences saved!')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notifPrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: AppTypography.sectionHeading),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryCoral),
              ),
            ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => const ElliMateLoading(),
        error: (_, __) => const ElliMateLoading(),
        data: (prefs) {
          _initFromPrefs(prefs);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what notifications you receive.',
                  style:
                      AppTypography.body.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightBorder),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _NotifToggle(
                        icon: Icons.local_laundry_service_rounded,
                        title: 'Laundry reminders',
                        subtitle: 'Get notified when your turn starts',
                        value: _laundryReminders,
                        onChanged: (v) {
                          setState(() => _laundryReminders = v);
                          _save();
                        },
                      ),
                      const Divider(
                          height: 1, indent: 68, color: AppColors.lightBorder),
                      _NotifToggle(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chat messages',
                        subtitle: 'Get notified about new messages',
                        value: _chatMessages,
                        onChanged: (v) {
                          setState(() => _chatMessages = v);
                          _save();
                        },
                      ),
                      const Divider(
                          height: 1, indent: 68, color: AppColors.lightBorder),
                      _NotifToggle(
                        icon: Icons.campaign_outlined,
                        title: 'Apartment updates',
                        subtitle: 'Get notified about important updates',
                        value: _apartmentUpdates,
                        onChanged: (v) {
                          setState(() => _apartmentUpdates = v);
                          _save();
                        },
                      ),
                      const Divider(
                          height: 1, indent: 68, color: AppColors.lightBorder),
                      _NotifToggle(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Booking confirmations',
                        subtitle: 'Get notified when bookings are confirmed',
                        value: _bookingConfirmations,
                        onChanged: (v) {
                          setState(() => _bookingConfirmations = v);
                          _save();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightCoral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryCoral, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryCoral,
          ),
        ],
      ),
    );
  }
}
