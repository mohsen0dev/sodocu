import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کنترلر تم سراسری اپ.
///
/// فقط وضعیت «تیره / روشن» را نگه می‌دارد و در SharedPreferences
/// ذخیره می‌کند. هیچ ارتباطی با منطق بازی ندارد.
abstract final class ThemeController {
  /// کلید ذخیرهٔ تم در SharedPreferences.
  static const String _prefsKey = 'theme_mode';

  /// وضعیت فعلی تم؛ پیش‌فرض تیره (همان حالتی که اپ با آن اجرا می‌شود).
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  /// خواندن تم ذخیره‌شده هنگام اجرای اپ (قبل از `runApp`).
  ///
  /// در صورت خطا، تم پیش‌فرض (تیره) باقی می‌ماند.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      if (stored == 'light') mode.value = ThemeMode.light;
      if (stored == 'dark') mode.value = ThemeMode.dark;
    } catch (_) {
      // SharedPreferences در دسترس نیست؛ تم پیش‌فرض حفظ می‌شود.
    }
  }

  /// تنظیم تم و ذخیرهٔ آن برای اجراهای بعدی.
  static Future<void> set(ThemeMode next) async {
    mode.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, next == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {
      // ذخیره‌سازی اختیاری است؛ خطا نباید تغییر تم را متوقف کند.
    }
  }

  /// برعکس کردن تم فعلی.
  static Future<void> toggle() =>
      set(mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
