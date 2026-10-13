import '../../core/l10n/app_strings.dart';

/// The date printed on a group photo: Solar Hijri in Persian ("۲۱ مهر ۱۴۰۵"),
/// day / month / year with the language's digits elsewhere.
String photoDate(AppStrings s, DateTime d) {
  if (s.languageCode == 'fa') {
    final (y, m, day) = toJalali(d);
    return '${s.n(day)} ${_jalaliMonths[m - 1]} ${s.n(y)}';
  }
  final dd = s.n(d.day), mm = s.n(d.month), yy = s.n(d.year);
  return s.isRtl ? '$yy/$mm/$dd' : '$dd.$mm.$yy';
}

const _jalaliMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

/// Gregorian → Solar Hijri (year, month, day).
(int, int, int) toJalali(DateTime date) {
  const gDaysInMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy = date.year, gm = date.month, gd = date.day;
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days =
      355666 +
      365 * gy +
      (gy2 + 3) ~/ 4 -
      (gy2 + 99) ~/ 100 +
      (gy2 + 399) ~/ 400 +
      gd +
      gDaysInMonth[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
  final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return (jy, jm, jd);
}
