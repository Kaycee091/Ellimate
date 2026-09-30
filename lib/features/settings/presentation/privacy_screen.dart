import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Privacy', style: AppTypography.sectionHeading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: AppTypography.screenHeading),
            const SizedBox(height: 8),
            Text(
              'Last updated: September 2025',
              style: AppTypography.small,
            ),
            const SizedBox(height: 20),
            _PrivacySection(
              title: 'Data We Collect',
              content:
                  'ElliMate collects only the data necessary to provide our apartment management service: your name, email address, and optional profile photo. We also store apartment information, laundry bookings, chat messages, and apartment updates associated with your account.',
            ),
            _PrivacySection(
              title: 'How We Use Your Data',
              content:
                  'Your data is used solely to power the ElliMate application — enabling real-time chat, laundry scheduling, and apartment communication between roommates. We do not sell your data to third parties.',
            ),
            _PrivacySection(
              title: 'Data Storage',
              content:
                  'Your data is stored securely using Supabase (PostgreSQL) with row-level security policies that ensure only authorised users can access apartment-specific data.',
            ),
            _PrivacySection(
              title: 'Your Rights',
              content:
                  'You may update or delete your account at any time through the Account Details screen. Deleting your account permanently removes your personal data from ElliMate.',
            ),
            _PrivacySection(
              title: 'Contact',
              content:
                  'For privacy-related questions, contact our support team through the Help & Support screen.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(content,
              style: AppTypography.body.copyWith(color: AppColors.secondaryText, height: 1.6)),
        ],
      ),
    );
  }
}
