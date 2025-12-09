import 'package:intl/intl.dart';

class AppDateUtils {
  // 格式化为日期字符串 (YYYY-MM-DD)
  static String formatDateToString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 从字符串解析日期
  static DateTime parseDateFromString(String dateString) {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  }

  // 格式化为时间字符串 (HH:mm)
  static String formatTimeToString(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // 格式化为日期时间字符串 (YYYY-MM-DD HH:mm)
  static String formatDateTimeToString(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  // 格式化为ISO 8601字符串
  static String formatToIso8601(DateTime date) {
    return date.toIso8601String();
  }

  // 从ISO 8601字符串解析日期时间
  static DateTime parseFromIso8601(String isoString) {
    return DateTime.parse(isoString);
  }

  // 获取今天的日期字符串
  static String getTodayString() {
    return formatDateToString(DateTime.now());
  }

  // 判断是否是今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // 判断是否是昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // 获取友好的日期显示文本
  static String getFriendlyDateString(DateTime date) {
    if (isToday(date)) {
      return '今天';
    } else if (isYesterday(date)) {
      return '昨天';
    } else {
      return formatDateToString(date);
    }
  }

  // 获取本周的开始日期（周一）
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // 获取本月的开始日期
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
}