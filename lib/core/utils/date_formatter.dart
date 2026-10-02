import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes left';
    } else {
      return 'Expired';
    }
  }

  static String formatDaysRemaining(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays < 0) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      return 'Ending Today';
    } else if (difference.inDays == 1) {
      return '1 day left';
    } else {
      return '${difference.inDays} days left';
    }
  }

  static int daysRemaining(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    return diff.inDays > 0 ? diff.inDays : 0;
  }
}
