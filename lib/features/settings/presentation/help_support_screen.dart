import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Help & Support', style: AppTypography.sectionHeading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 48, color: AppColors.white),
                  const SizedBox(height: 8),
                  Text(
                    'How can we help?',
                    style: AppTypography.sectionHeading
                        .copyWith(color: AppColors.white),
                  ),
                  Text(
                    "We're here to make apartment life easier.",
                    style: AppTypography.small
                        .copyWith(color: AppColors.white.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Frequently Asked Questions',
                style: AppTypography.sectionHeading),
            const SizedBox(height: 12),

            _FaqCard(
              question: 'How do I invite roommates to my apartment?',
              answer:
                  'Go to Settings → Apartment Settings to view your unique invite code. Share this code with your roommates so they can join using the "Join Apartment" option.',
            ),
            _FaqCard(
              question: 'How does laundry booking work?',
              answer:
                  'Go to the Laundry screen and tap "Book Laundry". Select a date and available time slot. Only one person can book each time slot, so conflicts are automatically prevented.',
            ),
            _FaqCard(
              question: 'Can I change my apartment?',
              answer:
                  'Currently, each user belongs to one apartment. Contact support if you need to switch apartments.',
            ),
            _FaqCard(
              question: 'How do I post apartment updates?',
              answer:
                  'Only apartment admins can post updates. If you are an admin, go to the Updates screen and tap "+ New Update".',
            ),
            _FaqCard(
              question: 'How do I turn off notifications?',
              answer:
                  'Go to Profile → Notifications to toggle individual notification types on or off.',
            ),

            const SizedBox(height: 28),
            Text('Contact Us', style: AppTypography.sectionHeading),
            const SizedBox(height: 12),

            _ContactCard(
              icon: Icons.email_outlined,
              title: 'Contact Support',
              subtitle: 'support@ellimate.app',
              color: AppColors.blue,
            ),
            const SizedBox(height: 10),
            _ContactCard(
              icon: Icons.bug_report_outlined,
              title: 'Report a Problem',
              subtitle: 'Tell us what went wrong',
              color: AppColors.primaryCoral,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ExpansionTile(
        title: Text(widget.question, style: AppTypography.bodyMedium),
        trailing: Icon(
          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: AppColors.primaryCoral,
        ),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.answer,
              style: AppTypography.body
                  .copyWith(color: AppColors.secondaryText, height: 1.6)),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMedium),
              Text(subtitle, style: AppTypography.small),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.secondaryText),
        ],
      ),
    );
  }
}
