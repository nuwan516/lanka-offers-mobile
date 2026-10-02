import '../utils/date_formatter.dart';

extension DateExtensions on DateTime {
  int daysRemaining() {
    final now = DateTime.now();
    final diff = this.difference(now);
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  bool get isExpired {
    return isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    final days = daysRemaining();
    return days >= 0 && days <= 7;
  }

  String get formattedDate => DateFormatter.formatDate(this);
  String get formattedDateTime => DateFormatter.formatDateTime(this);
  String get formattedTime => DateFormatter.formatTime(this);
  String get relativeTime => DateFormatter.formatRelative(this);
  String get daysRemainingText => DateFormatter.formatDaysRemaining(this);
}
