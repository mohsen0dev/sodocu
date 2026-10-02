/// Font family name for the app UI.

/// فرض بر این است که فونت Vazirmatn در پوشه assets/font قرار داده شده باشد.
/// این فایل بعداً می‌تواند حاوی دقیقاً نام فونت مورد استفاده باشد.
/// فعلاً ثابت خالی می‌گذاریم تا pubspec و ThemeData از آن استفاده نکنند.

abstract final class AppFonts {
  AppFonts._();

  /// نام خانواده فونت (هنوز تعریف نشده).
  static const vazirmatn = 'Vazirmatn';
}
