import 'package:flutter/material.dart';

/// پالت رنگ سراسری سودوکو.
///
/// فقط ثابت‌های خالص (بدون `BuildContext`) تا در هر جایی از جمله تست‌ها
/// — که `GetMaterialApp` پیش‌فرض و بدون extension سفارشی پمپ می‌شود —
/// قابل استفاده باشد.
///
/// هیچ رفتاری از بازی به این رنگ‌ها وابسته نیست؛ صرفاً نمای ظاهری را
/// یکدست می‌کنند.
abstract final class SudokuColors {
  /// رنگ اصلی برند اپ (همان آبی قدیمی تا ظاهر آشنا بماند).
  static const Color primary = Colors.blue;

  /// نسخهٔ پررنگ‌تر آبی برای حالت «انتخاب شده».
  static const Color primaryStrong = Color(0xFF1565C0); // == blue.shade700

  /// خطا / باخت / حذف.
  static const Color danger = Colors.red;
  static const Color dangerAccent = Colors.redAccent;

  /// هشدار و حالت یادداشت (بوردر خانهٔ انتخاب‌شده).
  static const Color warning = Colors.orange;

  /// هایلایت «همان عدد» روی جدول (خانهٔ ثابت) و بهترین رکورد.
  static const Color highlight = Colors.amber;

  /// حالت فعالِ اعتبارسنجی فوری (بوردر سبز بلوک‌ها).
  static const Color success = Colors.green;

  /// حالت چالش روزانه و اطلاعات جانبی.
  static const Color info = Colors.teal;

  /// هشدار شدید (شمارندهٔ خطاها در حالت رقابت رکوردی).
  static const Color ember = Colors.deepOrange;

  /// متن ثانویهٔ کم‌رنگ (یادداشت‌های درون جدول).
  static const Color noteText = Color(0xFF9E9E9E); // == grey.shade500
}
