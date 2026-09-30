import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, d MMM yyyy');
  static final DateFormat _relativeDateFormat = DateFormat('d MMM');
  static final DateFormat _bookingDateFormat = DateFormat('yyyy-MM-dd');

  static String formatTime(DateTime dt) => _timeFormat.format(dt.toLocal());

  static String formatDate(DateTime dt) => _dateFormat.format(dt.toLocal());

  static String formatFullDate(DateTime dt) =>
      _fullDateFormat.format(dt.toLocal());

  static String formatBookingDate(DateTime dt) =>
      _bookingDateFormat.format(dt);

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _relativeDateFormat.format(dt.toLocal());
  }

  static String formatChatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.inDays == 0) return _timeFormat.format(local);
    if (diff.inDays == 1) return 'Yesterday';
    return _relativeDateFormat.format(local);
  }

  static String timeSlotLabel(int hour) {
    final start = DateTime(2000, 1, 1, hour);
    final end = DateTime(2000, 1, 1, hour + 1);
    return '${_timeFormat.format(start)} - ${_timeFormat.format(end)}';
  }
}
