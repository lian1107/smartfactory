import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _displayFmt = DateFormat('MM月dd日');
  static final _displayTimeFmt = DateFormat('MM月dd日 HH:mm');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFmt.format(date);
  }

  static String formatDisplayDate(DateTime? date) {
    if (date == null) return '-';
    return _displayFmt.format(date);
  }

  static String formatDisplayDateTime(DateTime? date) {
    if (date == null) return '-';
    return _displayTimeFmt.format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return '刚刚';
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return _displayFmt.format(date);
    }
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  static bool isDueToday(DateTime? dueDate) {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate.year == today.year &&
        dueDate.month == today.month &&
        dueDate.day == today.day;
  }

  static bool isDueThisWeek(DateTime? dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    return dueDate.isAfter(now) && dueDate.isBefore(weekEnd);
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
