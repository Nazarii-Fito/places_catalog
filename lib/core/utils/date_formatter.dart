import '../constants/app_strings.dart';

/// Formats dates the way the design shows them, e.g. `Oct 14`, `Nov 02`.
///
/// Pure presentation helper — kept tiny on purpose so the app needs no
/// `intl` dependency.
String formatShortDate(DateTime date) {
  final String month = AppStrings.monthsShort[date.month - 1];
  final String day = date.day.toString().padLeft(2, '0');
  return '$month $day';
}
