import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, h:mm a');

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatPickupWindow(DateTime start, DateTime end) {
    return '${formatTime(start)} – ${formatTime(end)}';
  }

  static String getRemainingTimeLabel(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Window closed';
    }

    if (difference.inHours > 0) {
      final mins = difference.inMinutes % 60;
      return '${difference.inHours}h ${mins}m left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return '${difference.inSeconds}s left';
    }
  }

  static bool isExpired(DateTime deadline) {
    return DateTime.now().isAfter(deadline);
  }
}
