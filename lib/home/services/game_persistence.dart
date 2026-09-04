import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// سرویس ذخیره‌سازی و بازیابی وضعیت بازی در SharedPreferences.
///
/// تمام تعاملات با SharedPreferences را متمرکز می‌کند:
/// - ذخیره/بازیابی بازی فعال
/// - بهترین زمان‌ها
/// - آمار کلی
/// - تلاش چالش روزانه
/// - تنظیمات آشناسازی
///
/// با تزریق `SharedPreferences` در سازنده، قابلیت جایگزینی با
/// Mock در تست‌ها فراهم می‌شود.
class GamePersistence {
  SharedPreferences? _prefs;

  GamePersistence(this._prefs);

  /// به‌روزرسانی نمونهٔ SharedPreferences (مثلاً پس از تلاش مجدد در پس‌زمینه).
  void updatePrefs(SharedPreferences prefs) => _prefs = prefs;

  /// آیا SharedPreferences در دسترس است؟
  bool get isAvailable => _prefs != null;

  // ─────────────────────── ثابت‌های کلید ───────────────────────

  static const savedGameKey = 'sudoku.saved_game';
  static const bestTimesKey = 'sudoku.best_times';
  static const dailyAttemptKey = 'sudoku.daily_attempt';
  static const statsKey = 'sudoku.stats';
  static const onboardingKey = 'sudoku.onboarding_seen';

  // ─────────────────────── بازی فعال ───────────────────────

  /// رشتهٔ JSON بازی ذخیره‌شده را برمی‌گرداند، یا `null` اگر بازی‌ای نیست.
  String? loadSavedGame() => _prefs?.getString(savedGameKey);

  /// اطلاعات بازی فعال را به صورت JSON ذخیره می‌کند.
  Future<bool> saveGame(String json) =>
      _prefs?.setString(savedGameKey, json) ?? Future.value(false);

  /// بازی ذخیره‌شده را حذف می‌کند.
  Future<bool> deleteGame() =>
      _prefs?.remove(savedGameKey) ?? Future.value(false);

  // ─────────────────────── بهترین زمان‌ها ───────────────────────

  /// دیتای بهترین زمان‌ها را از حافظه می‌خواند.
  String? loadBestTimesRaw() => _prefs?.getString(bestTimesKey);

  /// ذخیرهٔ دیتای بهترین زمان‌ها.
  Future<bool> saveBestTimes(Map<String, int> bestTimes) =>
      _prefs?.setString(bestTimesKey, jsonEncode(bestTimes)) ??
      Future.value(false);

  // ─────────────────────── آمار ───────────────────────

  /// دیتای آمار را از حافظه می‌خواند.
  String? loadStatsRaw() => _prefs?.getString(statsKey);

  /// ذخیرهٔ دیتای آمار.
  Future<bool> saveStats(Map<String, dynamic> stats) =>
      _prefs?.setString(statsKey, jsonEncode(stats)) ?? Future.value(false);

  // ─────────────────────── چالش روزانه ───────────────────────

  /// کلید تلاش امروز را برمی‌گرداند.
  String? loadDailyAttempt() => _prefs?.getString(dailyAttemptKey);

  /// ثبت تلاش امروز.
  Future<bool> saveDailyAttempt(String todayKey) =>
      _prefs?.setString(dailyAttemptKey, todayKey) ?? Future.value(false);

  /// حذف تلاش روزانه.
  Future<bool> deleteDailyAttempt() =>
      _prefs?.remove(dailyAttemptKey) ?? Future.value(false);

  // ─────────────────────── آشناسازی ───────────────────────

  bool isOnboardingSeen() => _prefs?.getBool(onboardingKey) ?? false;

  Future<bool> setOnboardingSeen() =>
      _prefs?.setBool(onboardingKey, true) ?? Future.value(false);

  // ─────────────────────── حذف کلید ───────────────────────

  /// حذف هر کلید دلخواه.
  Future<bool> remove(String key) =>
      _prefs?.remove(key) ?? Future.value(false);

  // ─────────────────────── کمکی‌ها ───────────────────────

  /// تلاش برای دریافت SharedPreferences با زمان‌بندی مشخص.
  ///
  /// در صورت تایم‌اوت، null برمی‌گرداند.
  static Future<SharedPreferences?> tryGetInstance({
    Duration timeout = const Duration(seconds: 1),
  }) async {
    try {
      return await SharedPreferences.getInstance().timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }
}
