import '../constants/app_strings.dart';

// Pure presentation helpers that format dates the way the design shows
// them — kept tiny on purpose so the app needs no `intl` dependency.

/// `Oct 14`, `Nov 02`.
String formatShortDate(DateTime date) {
  final String month = AppStrings.monthsShort[date.month - 1];
  final String day = date.day.toString().padLeft(2, '0');
  return '$month $day';
}

/// `Sep 24, 2026`.
String formatMediumDate(DateTime date) {
  final String month = AppStrings.monthsShort[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

/// `October 14, 2023`.
String formatLongDate(DateTime date) {
  final String month = AppStrings.monthsLong[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

/// `Oct 14, 4:18 PM`.
String formatDateTime(DateTime date) {
  final int hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final String minute = date.minute.toString().padLeft(2, '0');
  final String period = date.hour < 12 ? AppStrings.am : AppStrings.pm;
  final String month = AppStrings.monthsShort[date.month - 1];
  return '$month ${date.day}, $hour12:$minute $period';
}
