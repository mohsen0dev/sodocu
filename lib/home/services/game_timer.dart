import 'dart:async';

/// سرویس مدیریت تایمر بازی.
///
/// این کلاس لایهٔ باریکی دور `Timer.periodic` می‌پیچد تا:
/// ۱. منطق تایمر از کنترلر جدا شود و قابلیت تست داشته باشد.
/// ۲. شروع/توقف/بررسی فعال بودن در یک مکان متمرکز باشد.
class GameTimer {
  Timer? _timer;

  /// آیا تایمر در حال اجراست؟
  bool get isActive => _timer?.isActive ?? false;

  /// شروع تایمر با فاصلهٔ [interval] بین هر ضربه.
  ///
  /// [onTick] در هر ثانیه فراخوانی می‌شود؛ مسئولیت افزایش شمارنده
  /// و تصمیم‌گیری‌های بازی (مثلاً پایان زمان) بر عهدهٔ فراخواننده است.
  void start({required Duration interval, required void Function() onTick}) {
    stop();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  /// متوقف کردن تایمر.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// آزادسازی منابع (فراخوانی در onClose کنترلر).
  void dispose() => stop();
}
