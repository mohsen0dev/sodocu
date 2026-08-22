import 'package:flutter_test/flutter_test.dart';
import 'package:sodocu/utils/jalali.dart';

void main() {
  group('jalaliFromGregorian', () {
    test('نوروز ۱۴۰۴ برابر با ۲۱ مارس ۲۰۲۵ است', () {
      expect(
        jalaliFromGregorian(DateTime(2025, 3, 21)),
        const JalaliDate(1404, 1, 1),
      );
    });

    test('نوروز ۱۴۰۵ برابر با ۲۱ مارس ۲۰۲۶ است', () {
      expect(
        jalaliFromGregorian(DateTime(2026, 3, 21)),
        const JalaliDate(1405, 1, 1),
      );
    });

    test('سال کبیسهٔ ۱۴۰۳ از ۲۰ مارس ۲۰۲۴ شروع می‌شود', () {
      expect(
        jalaliFromGregorian(DateTime(2024, 3, 20)),
        const JalaliDate(1403, 1, 1),
      );
    });

    test('۲۲ بهمن ۱۳۵۷ برابر با ۱۱ فوریهٔ ۱۹۷۹ است', () {
      expect(
        jalaliFromGregorian(DateTime(1979, 2, 11)),
        const JalaliDate(1357, 11, 22),
      );
    });

    test('نمونهٔ مرجع کتابخانهٔ jalaali-js', () {
      expect(
        jalaliFromGregorian(DateTime(2016, 4, 11)),
        const JalaliDate(1395, 1, 23),
      );
    });

    test('انتهای سال و ابتدای سال بعد درست جابه‌جا می‌شود', () {
      // ۲۰ اسفند ۱۴۰۴ و ۲۹ اسفند ۱۴۰۵ (سال غیرکبیسه)
      expect(
        jalaliFromGregorian(DateTime(2026, 3, 11)),
        const JalaliDate(1404, 12, 20),
      );
      expect(
        jalaliFromGregorian(DateTime(2027, 3, 20)),
        const JalaliDate(1405, 12, 29),
      );
      expect(
        jalaliFromGregorian(DateTime(2027, 3, 21)),
        const JalaliDate(1406, 1, 1),
      );
    });
  });

  group('فرمت‌بندی', () {
    test('toPersianDigits ارقام را فارسی می‌کند', () {
      expect(toPersianDigits(1405), '۱۴۰۵');
      expect(toPersianDigits(29), '۲۹');
      expect(toPersianDigits(0), '۰');
    });

    test('formatJalaliFull نام روز و ماه را فارسی نشان می‌دهد', () {
      // ۲۱ مارس ۲۰۲۵ = جمعه ۱ فروردین ۱۴۰۴
      expect(formatJalaliFull(DateTime(2025, 3, 21)), 'جمعه ۱ فروردین ۱۴۰۴');
      // ۲۱ اوت ۲۰۲۶ = جمعه ۳۰ مرداد ۱۴۰۵
      expect(formatJalaliFull(DateTime(2026, 8, 21)), 'جمعه ۳۰ مرداد ۱۴۰۵');
    });

    test('jalaliDateKey کلید یکتای روز را می‌سازد', () {
      expect(jalaliDateKey(DateTime(2025, 3, 21)), '1404-01-01');
      expect(jalaliDateKey(DateTime(2026, 8, 21)), '1405-05-30');
    });
  });
}
