import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/ellimate_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo area
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.brandGradient,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_rounded, color: AppColors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ElliMate',
                    style: AppTypography.largeHeading.copyWith(
                      fontSize: 28,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Main card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      'Live together.\nCommunicate better.',
                      style: AppTypography.largeHeading.copyWith(
                        fontSize: 28,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Make apartment life easier with shared schedules, chat, and apartment updates.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Feature icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FeatureIcon(
                          icon: Icons.calendar_today_rounded,
                          label: 'Schedule',
                        ),
                        _FeatureIcon(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Chat',
                        ),
                        _FeatureIcon(
                          icon: Icons.apartment_rounded,
                          label: 'Apartment',
                        ),
                        _FeatureIcon(
                          icon: Icons.people_rounded,
                          label: 'Roommates',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Buttons
              ElliMateButton(
                label: 'Get Started',
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 12),
              ElliMateOutlinedButton(
                label: 'Log In',
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.lightCoral,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryCoral, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.secondaryText)),
      ],
    );
  }
}
