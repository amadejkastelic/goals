import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 6) {
      return DateFormat.EEEE().format(date);
    } else if (difference < -1 && difference >= -6) {
      return 'Last ${DateFormat.EEEE().format(date)}';
    } else {
      return formatDate(date);
    }
  }

  static String formatDateWithRelative(DateTime date) {
    final relative = formatRelative(date);
    if (relative == 'Today' ||
        relative == 'Tomorrow' ||
        relative == 'Yesterday') {
      return '$relative, ${DateFormat.MMMd().format(date)}';
    }
    return relative;
  }
}
