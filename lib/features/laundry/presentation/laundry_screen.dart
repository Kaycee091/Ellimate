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

final laundryBookingsProvider = FutureProvider<List<LaundryBooking>>((ref) async {
  final apartment = await ref.watch(currentApartmentProvider.future);
  if (apartment == null) return [];
  return ref.read(laundryRepositoryProvider).fetchBookings(
    apartmentId: apartment.id,
  );
});

class LaundryScreen extends ConsumerWidget {
  const LaundryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(laundryBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laundry', style: AppTypography.screenHeading),
                        Text('Laundry Schedule', style: AppTypography.small),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(laundryBookingsProvider),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),

            Expanded(
              child: bookingsAsync.when(
                loading: () => const ElliMateLoading(),
                error: (e, _) => ElliMateErrorState(
                  message: 'Unable to load laundry schedule.',
                  onRetry: () => ref.invalidate(laundryBookingsProvider),
                ),
                data: (bookings) => RefreshIndicator(
                  color: AppColors.primaryCoral,
                  onRefresh: () async => ref.invalidate(laundryBookingsProvider),
                  child: bookings.isEmpty
                      ? ElliMateEmptyState(
                          icon: Icons.local_laundry_service_rounded,
                          title: 'No laundry bookings yet',
                          subtitle: 'Book a slot to get started.',
                          actionLabel: 'Book Laundry',
                          onAction: () => context.push('/laundry/book'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: bookings.length,
                          itemBuilder: (context, i) =>
                              _LaundryBookingCard(booking: bookings[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/laundry/book'),
        backgroundColor: AppColors.primaryCoral,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Book laundry', style: AppTypography.bodySemiBold.copyWith(color: AppColors.white)),
      ),
    );
  }
}

class _LaundryBookingCard extends StatelessWidget {
  const _LaundryBookingCard({required this.booking});
  final LaundryBooking booking;

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.current:
        return AppColors.success;
      case BookingStatus.upcoming:
        return AppColors.blue;
      case BookingStatus.completed:
        return AppColors.secondaryText;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case BookingStatus.current:
        return 'CURRENT';
      case BookingStatus.upcoming:
        return 'UPCOMING';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: booking.status == BookingStatus.current
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.lightBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ElliMateAvatar(
            imageUrl: booking.userAvatarUrl,
            name: booking.userName ?? '?',
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.userName ?? 'Unknown',
                  style: AppTypography.bodySemiBold,
                ),
                Text(
                  '${DateFormat('d MMM').format(booking.bookingDate)} · ${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}',
                  style: AppTypography.small,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.caption.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
