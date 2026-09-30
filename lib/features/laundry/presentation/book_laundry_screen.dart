import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/widgets/ellimate_button.dart';
import 'laundry_screen.dart';

class BookLaundryScreen extends ConsumerStatefulWidget {
  const BookLaundryScreen({super.key});

  @override
  ConsumerState<BookLaundryScreen> createState() => _BookLaundryScreenState();
}

class _BookLaundryScreenState extends ConsumerState<BookLaundryScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedSlot;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  String? _errorMessage;
  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _loadBookedSlots();
  }

  Future<void> _loadBookedSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final apartment = await ref.read(currentApartmentProvider.future);
      if (apartment == null) return;
      final slots = await ref.read(laundryRepositoryProvider).fetchBookedSlots(
        apartmentId: apartment.id,
        date: _selectedDate,
      );
      if (mounted) setState(() => _bookedSlots = slots);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final apartment = await ref.read(currentApartmentProvider.future);
      if (user == null || apartment == null) throw const AppAuthException(message: 'Not authenticated.');

      final startHour = AppConstants.laundryTimeSlots[_selectedSlot!];
      final endHour = startHour + 1;
      final startTime = '${startHour.toString().padLeft(2, '0')}:00:00';
      final endTime = '${endHour.toString().padLeft(2, '0')}:00:00';

      await ref.read(laundryRepositoryProvider).createBooking(
        apartmentId: apartment.id,
        userId: user.id,
        bookingDate: _selectedDate,
        startTime: startTime,
        endTime: endTime,
      );

      ref.invalidate(laundryBookingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laundry slot booked successfully!')),
        );
        context.pop();
      }
    } on ConflictException catch (e) {
      setState(() => _errorMessage = e.message);
      _loadBookedSlots();
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Unable to book slot. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSlotBooked(int hour) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:00:00';
    return _bookedSlots.contains(timeStr);
  }

  bool _isSlotPast(int hour) {
    final now = DateTime.now();
    final slotDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour);
    return slotDate.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Book Laundry', style: AppTypography.sectionHeading),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selector
                  Text('Select date', style: AppTypography.sectionHeading),
                  const SizedBox(height: 12),
                  _DateSelector(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                        _selectedSlot = null;
                      });
                      _loadBookedSlots();
                    },
                  ),

                  const SizedBox(height: 24),
                  Text('Select time slot', style: AppTypography.sectionHeading),
                  const SizedBox(height: 12),

                  if (_isLoadingSlots)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryCoral))
                  else
                    Column(
                      children: AppConstants.laundryTimeSlots
                          .asMap()
                          .entries
                          .map((entry) => _TimeSlotCard(
                                index: entry.key,
                                hour: entry.value,
                                isSelected: _selectedSlot == entry.key,
                                isBooked: _isSlotBooked(entry.value),
                                isPast: _isSlotPast(entry.value),
                                onTap: () {
                                  if (!_isSlotBooked(entry.value) && !_isSlotPast(entry.value)) {
                                    setState(() => _selectedSlot = entry.key);
                                  }
                                },
                              ))
                          .toList(),
                    ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.small.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom,
        ),
        child: ElliMateButton(
          label: 'Confirm Booking',
          onPressed: _selectedSlot != null ? _confirmBooking : null,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate, required this.onDateChanged});
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(14, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final date = dates[i];
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);

          return GestureDetector(
            onTap: () => onDateChanged(date),
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryCoral : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primaryCoral : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(date),
                    style: AppTypography.bodySemiBold.copyWith(
                      color: isSelected ? AppColors.white : AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.white.withValues(alpha: 0.8) : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({
    required this.index,
    required this.hour,
    required this.isSelected,
    required this.isBooked,
    required this.isPast,
    required this.onTap,
  });

  final int index;
  final int hour;
  final bool isSelected;
  final bool isBooked;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final startTime = '${hour.toString().padLeft(2, '0')}:00';
    final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';
    final isDisabled = isBooked || isPast;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCoral
              : isDisabled
                  ? AppColors.lightBorder.withValues(alpha: 0.5)
                  : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryCoral
                : isDisabled
                    ? AppColors.border.withValues(alpha: 0.5)
                    : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              '$startTime - $endTime',
              style: AppTypography.bodySemiBold.copyWith(
                color: isSelected
                    ? AppColors.white
                    : isDisabled
                        ? AppColors.secondaryText.withValues(alpha: 0.5)
                        : AppColors.primaryNavy,
              ),
            ),
            const Spacer(),
            if (isBooked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Booked',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (isPast)
              Text('Past', style: AppTypography.small.copyWith(color: AppColors.secondaryText.withValues(alpha: 0.5)))
            else if (isSelected)
              const Icon(Icons.radio_button_checked_rounded, color: AppColors.white, size: 20)
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Available',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.border, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
