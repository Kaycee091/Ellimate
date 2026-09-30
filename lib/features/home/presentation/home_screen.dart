import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/laundry_booking.dart';
import '../../../shared/widgets/ellimate_avatar.dart';
import '../../../shared/widgets/ellimate_states.dart';

final _homeDataProvider = FutureProvider<_HomeData>((ref) async {
  final user = ref.watch(currentUserProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  final apartment = await ref.watch(currentApartmentProvider.future);

  if (user == null || apartment == null) {
    return _HomeData(greeting: 'Hello', profile: null, apartment: null, bookings: []);
  }

  final hour = DateTime.now().hour;
  String greeting;
  if (hour < 12) {
    greeting = 'Good morning';
  } else if (hour < 17) {
    greeting = 'Good afternoon';
  } else {
    greeting = 'Good evening';
  }

  List<LaundryBooking> bookings = [];
  try {
    bookings = await ref.read(laundryRepositoryProvider).fetchBookings(
      apartmentId: apartment.id,
    );
  } catch (_) {}

  return _HomeData(
    greeting: greeting,
    profile: profile,
    apartment: apartment,
    bookings: bookings,
  );
});

class _HomeData {
  final String greeting;
  final dynamic profile;
  final dynamic apartment;
  final List<LaundryBooking> bookings;

  _HomeData({
    required this.greeting,
    required this.profile,
    required this.apartment,
    required this.bookings,
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(_homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: homeData.when(
        loading: () => const ElliMateLoading(),
        error: (e, _) => ElliMateErrorState(
          message: 'Unable to load home. Please try again.',
          onRetry: () => ref.invalidate(_homeDataProvider),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.primaryCoral,
          backgroundColor: AppColors.white,
          onRefresh: () async => ref.invalidate(_homeDataProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HomeHeader(data: data)),
              SliverToBoxAdapter(child: _LaundryCard(bookings: data.bookings, apartmentId: data.apartment?.id)),
              const SliverToBoxAdapter(child: _QuickActions()),
              SliverToBoxAdapter(child: _RecentSection(data: data)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.data});
  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    final name = data.profile?.name ?? 'there';
    final firstName = name.split(' ').first;
    final emoji = _greetingEmoji(data.greeting);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ data.greeting}, $firstName $emoji',
                  style: AppTypography.sectionHeading.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                if (data.apartment != null)
                  Text(
                    data.apartment!.name,
                    style: AppTypography.small.copyWith(color: AppColors.primaryCoral),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: ElliMateAvatar(
              imageUrl: data.profile?.avatarUrl,
              name: data.profile?.name ?? '?',
              radius: 22,
            ),
          ),
        ],
      ),
    );
  }

  String _greetingEmoji(String greeting) {
    if (greeting.contains('morning')) return '☀️';
    if (greeting.contains('afternoon')) return '👋';
    return '🌙';
  }
}

class _LaundryCard extends StatelessWidget {
  const _LaundryCard({required this.bookings, required this.apartmentId});
  final List<LaundryBooking> bookings;
  final String? apartmentId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    LaundryBooking? current;
    LaundryBooking? next;

    for (final b in bookings) {
      final bookDateStr = DateFormat('yyyy-MM-dd').format(b.bookingDate);
      if (bookDateStr == todayStr) {
        if (b.startTime.compareTo(timeStr) <= 0 && b.endTime.compareTo(timeStr) > 0) {
          current = b;
        } else if (b.startTime.compareTo(timeStr) > 0 && next == null) {
          next = b;
        }
      } else {
        next ??= b;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () => context.go('/laundry'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lightBorder),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lightCoral,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_laundry_service_rounded,
                        color: AppColors.primaryCoral, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Laundry', style: AppTypography.bodySemiBold),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.secondaryText),
                ],
              ),
              const SizedBox(height: 16),
              if (current != null) ...[
                _LaundryRow(label: 'Now', booking: current),
                const SizedBox(height: 8),
              ],
              if (next != null) ...[
                _LaundryRow(label: 'Next', booking: next),
              ],
              if (current == null && next == null) ...[
                Text(
                  'No upcoming laundry bookings',
                  style: AppTypography.small,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.go('/laundry/book'),
                  child: Text(
                    'Book a slot →',
                    style: AppTypography.smallMedium.copyWith(
                      color: AppColors.primaryCoral,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LaundryRow extends StatelessWidget {
  const _LaundryRow({required this.label, required this.booking});
  final String label;
  final LaundryBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElliMateAvatar(
          imageUrl: booking.userAvatarUrl,
          name: booking.userName ?? '?',
          radius: 12,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            booking.userName ?? 'Unknown',
            style: AppTypography.bodySemiBold.copyWith(fontSize: 14),
          ),
        ),
        Text(
          '${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}',
          style: AppTypography.small,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: AppTypography.sectionHeading),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.local_laundry_service_rounded,
                  label: 'Laundry',
                  route: '/laundry',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  route: '/chat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.campaign_rounded,
                  label: 'Updates',
                  route: '/updates',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.people_rounded,
                  label: 'Roommates',
                  route: '/roommates',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lightCoral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryCoral, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.smallMedium.copyWith(color: AppColors.primaryNavy)),
          ],
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.data});
  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    if (data.bookings.isEmpty) return const SizedBox.shrink();

    // Show next upcoming booking
    final upcoming = data.bookings.where((b) => b.status == BookingStatus.upcoming).take(1).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming', style: AppTypography.sectionHeading),
          const SizedBox(height: 12),
          ...upcoming.map((b) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                ElliMateAvatar(
                  imageUrl: b.userAvatarUrl,
                  name: b.userName ?? '?',
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.userName ?? 'Unknown', style: AppTypography.bodyMedium),
                      Text(
                        '${DateFormat('d MMM').format(b.bookingDate)} · ${b.startTime.substring(0,5)} - ${b.endTime.substring(0,5)}',
                        style: AppTypography.small,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightCoral,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'UPCOMING',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryCoral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
