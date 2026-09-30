import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/widgets/ellimate_avatar.dart';
import '../../../shared/widgets/ellimate_states.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final apartmentAsync = ref.watch(currentApartmentProvider);
    final membershipAsync = ref.watch(currentMembershipProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: profileAsync.when(
        loading: () => const ElliMateLoading(),
        error: (e, _) => ElliMateErrorState(
          message: 'Unable to load profile.',
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          final name = profile?.name ?? 'Unknown';
          final role = membershipAsync.value?.role == 'admin' ? 'Admin' : 'Member';
          final apartmentName = apartmentAsync.value?.name ?? '';

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ElliMateAvatar(
                              imageUrl: profile?.avatarUrl,
                              name: name,
                              radius: 44,
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryCoral,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_rounded,
                                    size: 14, color: AppColors.white),
                                onPressed: () =>
                                    context.push('/settings/account'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: AppTypography.sectionHeading),
                        const SizedBox(height: 2),
                        if (apartmentName.isNotEmpty)
                          Text(
                            apartmentName,
                            style: AppTypography.small
                                .copyWith(color: AppColors.primaryCoral),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightCoral,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryCoral,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu items
                  _ProfileMenu(
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Account details',
                        onTap: () => context.push('/settings/account'),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => context.push('/settings/notifications'),
                      ),
                      _MenuItem(
                        icon: Icons.apartment_rounded,
                        label: 'Apartment settings',
                        onTap: () => context.push('/settings/apartment'),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Privacy',
                        onTap: () => context.push('/settings/privacy'),
                      ),
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () => context.push('/settings/help'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LogoutTile(ref: ref),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lightCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon,
                      color: AppColors.primaryCoral, size: 20),
                ),
                title: Text(item.label, style: AppTypography.body),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.secondaryText),
                onTap: item.onTap,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1,
                    indent: 68,
                    color: AppColors.lightBorder),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded,
              color: AppColors.error, size: 20),
        ),
        title: Text(
          'Log out',
          style: AppTypography.body.copyWith(color: AppColors.error),
        ),
        onTap: () => _confirmLogout(context, widgetRef),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef widgetRef) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content:
            const Text('Are you sure you want to log out of ElliMate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widgetRef.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/welcome');
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
