import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('About', style: AppTypography.sectionHeading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.home_rounded,
                  size: 52, color: AppColors.white),
            ),
            const SizedBox(height: 16),
            Text(AppConstants.appName,
                style: AppTypography.largeHeading.copyWith(fontSize: 30)),
            const SizedBox(height: 4),
            Text(
              AppConstants.appTagline,
              style: AppTypography.body.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightCoral,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version ${AppConstants.appVersion}',
                style: AppTypography.small.copyWith(
                  color: AppColors.primaryCoral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  _AboutRow(label: 'Developer', value: 'ElliMate Team'),
                  const Divider(height: 20, color: AppColors.lightBorder),
                  _AboutRow(label: 'Version', value: AppConstants.appVersion),
                  const Divider(height: 20, color: AppColors.lightBorder),
                  _AboutRow(label: 'Platform', value: 'Android'),
                  const Divider(height: 20, color: AppColors.lightBorder),
                  _AboutRow(label: 'Backend', value: 'Supabase'),
                  const Divider(height: 20, color: AppColors.lightBorder),
                  _AboutRow(label: 'Framework', value: 'Flutter'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '© 2025 ElliMate. All rights reserved.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body.copyWith(color: AppColors.secondaryText)),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}
