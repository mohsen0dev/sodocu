// ابزارهای تقویم جلالی (شمسی).
//
// تبدیل تاریخ میلادی به جلالی بر پایهٔ الگوریتم «بورکوفسکی» (Borkowski)
// است؛ همان الگوریتم کتابخانهٔ jalaali-js که با نمونه‌های مرجع زیر تأیید
// شده است:
//   - g2d(2016, 4, 11) == 2457490
//   - toJalaali(2016, 4, 11) == { 1395, 1, 23 }
//   - jalCal(1390) == { leap: 3, gy: 2011, march: 21 }
//   - jalCal(1395) == { leap: 0, gy: 2016, march: 20 }

/// یک تاریخ جلالی (سال، ماه، روز).
class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  @override
  String toString() => 'JalaliDate($year, $month, $day)';

  @override
  bool operator ==(Object other) =>
      other is JalaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

const List<int> _jalaliBreaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210,
  1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
];

/// تقسیم صحیح به سبک جاوااسکریپت (برش به سمت صفر)، نه گرد کردن به پایین.
int _div(int a, int b) => (a / b).truncate();

/// باقیمانده به سبک جاوااسکریپت (هم‌علامت با مقسوم)، نه باقیماندهٔ Dart.
int _mod(int a, int b) => a - _div(a, b) * b;

/// تبدیل تاریخ میلادی به عدد ژولیانی (JDN).
int _g2d(int gy, int gm, int gd) {
  var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
      _div(153 * _mod(gm + 9, 12) + 2, 5) +
      gd -
      34840408;
  d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
  return d;
}

/// تبدیل عدد ژولیانی به تاریخ میلادی.
(int gy, int gm, int gd) _d2g(int jdn) {
  var j = 4 * jdn + 139361631;
  j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final i = _div(_mod(j, 1461), 4) * 5 + 308;
  final gd = _div(_mod(i, 153), 5) + 1;
  final gm = _mod(_div(i, 153), 12) + 1;
  final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
  return (gy, gm, gd);
}

/// مشخصات یک سال جلالی: آیا کبیسه است، سال میلادیِ آغاز آن و روزِ
/// فروردین ۱ در ماه مارس.
({int leap, int gy, int march}) _jalCal(int jy) {
  final bl = _jalaliBreaks.length;
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _jalaliBreaks[0];
  var jump = 0;
  var n = 0;

  if (jy < jp || jy >= _jalaliBreaks[bl - 1]) {
    throw ArgumentError('Invalid Jalaali year $jy');
  }

  for (var i = 1; i < bl; i += 1) {
    final jm = _jalaliBreaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ = leapJ + _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }
  n = jy - jp;

  leapJ = leapJ + _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;

  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;

  final march = 20 + leapJ - leapG;

  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  var leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;

  return (leap: leap, gy: gy, march: march);
}

/// تبدیل عدد ژولیانی به تاریخ جلالی.
JalaliDate _d2j(int jdn) {
  final (gy, _, _) = _d2g(jdn);
  var jy = gy - 621;
  final r = _jalCal(jy);
  final jdn1f = _g2d(gy, 3, r.march);
  var k = jdn - jdn1f;

  if (k >= 0) {
    if (k <= 185) {
      return JalaliDate(jy, 1 + _div(k, 31), _mod(k, 31) + 1);
    }
    k -= 186;
  } else {
    jy -= 1;
    k += 179;
    if (r.leap == 1) k += 1;
  }

  return JalaliDate(jy, 7 + _div(k, 30), _mod(k, 30) + 1);
}

/// تبدیل تاریخ میلادی به جلالی.
JalaliDate jalaliFromGregorian(DateTime date) {
  final jdn = _g2d(date.year, date.month, date.day);
  return _d2j(jdn);
}

/// نام ماه‌های جلالی.
const List<String> jalaliMonthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

/// نام روزهای هفته با شاخص [DateTime.weekday] (۱ = دوشنبه ... ۷ = یکشنبه).
const List<String> _weekdayNames = [
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
  'شنبه',
  'یکشنبه',
];

const String _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

/// تبدیل ارقام لاتین به فارسی.
String toPersianDigits(int value) {
  return value.toString().split('').map((char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39 ? _persianDigits[code - 0x30] : char;
  }).join();
}

/// نام روز هفتهٔ یک تاریخ میلادی به فارسی (شنبه تا جمعه).
String jalaliWeekdayName(DateTime date) => _weekdayNames[date.weekday - 1];

/// نمایش کامل تاریخ جلالی، مثلاً «پنجشنبه ۲۹ مرداد ۱۴۰۵».
String formatJalaliFull(DateTime date) {
  final j = jalaliFromGregorian(date);
  return '${jalaliWeekdayName(date)} ${toPersianDigits(j.day)} '
      '${jalaliMonthNames[j.month - 1]} ${toPersianDigits(j.year)}';
}

/// کلید یکتای روز جلالی، مثلاً «1405-05-29»؛ برای شناسایی «امروز» در
/// چالش روزانه استفاده می‌شود.
String jalaliDateKey(DateTime date) {
  final j = jalaliFromGregorian(date);
  return '${j.year.toString().padLeft(4, '0')}-'
      '${j.month.toString().padLeft(2, '0')}-'
      '${j.day.toString().padLeft(2, '0')}';
}
