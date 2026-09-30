import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class ApartmentSetupScreen extends StatelessWidget {
  const ApartmentSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header illustration
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.brandGradient,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Icon(Icons.apartment_rounded, size: 80, color: AppColors.white),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Apartment Setup',
                style: AppTypography.screenHeading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your apartment to get started with ElliMate.',
                style: AppTypography.body.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Create option
              _SetupOption(
                icon: Icons.add_home_rounded,
                title: 'Create an Apartment',
                subtitle: 'Set up a new apartment and invite roommates.',
                color: AppColors.primaryCoral,
                onTap: () => context.go('/apartment/create'),
              ),
              const SizedBox(height: 16),

              // Join option
              _SetupOption(
                icon: Icons.login_rounded,
                title: 'Join an Apartment',
                subtitle: 'Enter the invite code from your roommate.',
                color: AppColors.blue,
                onTap: () => context.go('/apartment/join'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupOption extends StatelessWidget {
  const _SetupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodySemiBold),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.small,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
