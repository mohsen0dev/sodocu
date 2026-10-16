import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/services/game_persistence.dart';
import 'package:sodocu/home/services/game_timer.dart';
import 'package:sodocu/home/services/sudoku_generator.dart';
import 'package:sodocu/utils/jalali.dart';

// بخش‌های جداگانهٔ کنترلر بازی.
//
// همهٔ این فایل‌ها part همین کتابخانه هستند تا متدها بر اساس
// مسئولیت تقسیم شوند بدون اینکه دسترسی به فیلدهای خصوصی
// یا رفتار بازی تغییری کند.
part 'controller/persistence_part.dart';
part 'controller/timer_part.dart';
part 'controller/modes_part.dart';
part 'controller/game_over_part.dart';
part 'controller/records_part.dart';
part 'controller/history_part.dart';
part 'controller/placement_part.dart';
part 'controller/notes_part.dart';
part 'controller/game_flow_part.dart';
part 'controller/display_part.dart';
part 'controller/units_part.dart';

/// سطح دشواری بازی سودوکو
enum Difficulty { easy, medium, hard }

/// حالت اجرای بازی؛ همه داده‌ها فقط روی همین دستگاه ذخیره می‌شوند.
enum GameMode { classic, timed, noHints, daily, record }

/// مدل داده برای هر خانه
class CellData implements CellLike {
  @override
  int value; // 0 = خالی
  Set<int> notes;
  @override
  bool isFixed; // آیا جزو پازل اولیه است (قابل تغییر نیست)

  CellData({this.value = 0, this.isFixed = false, Set<int>? notes})
      : notes = notes ?? {};

  CellData copy() {
    return CellData(value: value, isFixed: isFixed, notes: Set.from(notes));
  }
}

class HomeController extends GetxController {
  // ==================== سرویس‌ها ====================

  final GameTimer _timer = GameTimer();
  GamePersistence? _persistence;

  // ==================== متغیرهای اصلی ====================

  /// سلول‌های بازی (منبع واحد داده)
  late RxList<List<CellData>> cells;

  /// راه‌حل کامل و نهایی برد بازی
  List<List<int>>? _solution;

  /// لیستی از اعداد اولیه پازل
  List<List<int>>? puzzle;

  // ==================== وضعیت‌های UI ====================

  final int maxHelperUses = 3;
  var currentHelperUses = 0.obs;

  /// حداکثر خطاهای مجاز در حالت رقابت رکوردی (۳ خطا = باخت).
  static const int maxMistakes = 3;

  /// تعداد خطاهای ثبت‌شده در حالت رقابت رکوردی.
  final RxInt mistakes = 0.obs;

  /// خانه‌ای که آخرین خطای رکوردی در آن رخ داده (برای انیمیشن لرزش).
  int _mistakeRow = -1;
  int _mistakeCol = -1;

  /// نشانهٔ افزایشی برای راه‌اندازی مجدد انیمیشن خطا.
  final RxInt mistakeFlashToken = 0.obs;

  RxBool noteMode = false.obs;
  RxBool isActive = false.obs;

  /// نمایش اعداد ثابت (ویجت اعداد پایین صفحه)
  RxBool isShow = false.obs;

  /// حالت فعلی بازی.
  Rx<GameMode> gameMode = GameMode.classic.obs;

  /// زمان سپری‌شده از شروع بازی بر حسب ثانیه.
  final RxInt elapsedSeconds = 0.obs;
  static const int timedGameSeconds = 5 * 60;
  final RxInt remainingSeconds = timedGameSeconds.obs;
  final RxBool isGameOver = false.obs;

  /// سطح ثابت چالش روزانه؛ پازل هر روز یکسان و مستقل از انتخاب کاربر است.
  static const Difficulty dailyDifficulty = Difficulty.medium;

  /// بهترین رکورد محلی بر اساس حالت و سطح دشواری.
  final RxMap<String, int> bestTimes = <String, int>{}.obs;

  /// تعداد خانه‌های پر شده (غیرصفر)
  final RxInt completedCells = 0.obs;

  /// تعداد خانه‌های خالی باقی‌مانده
  final RxInt emptyCells = 81.obs;

  /// آمار کلی برای داشبورد رکوردها.
  final RxInt gamesCompleted = 0.obs;
  final RxInt totalCompletedSeconds = 0.obs;
  final RxInt bestStreak = 0.obs;

  Rx<Difficulty> difficulty = Difficulty.easy.obs;

  /// عدد انتخاب شده توسط کاربر (0 = حالت پاک کردن، 1-9 = اعداد)
  var selectedNumber = 0.obs;

  /// عددی که در حال نمایش افکت تکمیل ۹تایی است
  RxnInt celebratingNumber = RxnInt();

  /// واحدهای در حال جشن (row-0..8, col-0..8, box-0..8)
  RxSet<String> celebratingUnits = RxSet<String>();

  /// برای راه‌اندازی مجدد انیمیشن واحدها
  var celebrationToken = 0.obs;

  final Set<int> _completedRows = {};
  final Set<int> _completedCols = {};
  final Set<int> _completedBoxes = {};

  int? selectedRow;
  int? selectedCol;

  // شمارش تعداد استفاده از هر عدد 1 تا 9
  RxMap<int, int> numberUsage = RxMap<int, int>({
    for (var i = 1; i <= 9; i++) i: 0,
  });

  // ==================== تاریخچه (Undo/Redo) ====================

  final RxList<List<List<CellData>>> _undoStack = <List<List<CellData>>>[].obs;
  final RxList<List<List<CellData>>> _redoStack = <List<List<CellData>>>[].obs;
  RxBool canUndo = false.obs;
  RxBool canRedo = false.obs;

  // ==================== وضعیت بارگذاری ====================
  RxBool isLoading = true.obs;

  bool _hasActiveGame = false;
  bool _isRestoring = false;
  bool _isSaving = false;
  bool _saveQueued = false;
  int _gameSession = 0;

  /// استریک فعلی چالش روزانه و آخرین روزی که تکمیل شده است.
  int _currentStreak = 0;
  String? _lastDailyCompletedKey;

  // ==================== ثابت‌ها ====================
  static const Map<Difficulty, int> cluesCount = {
    Difficulty.easy: 40,
    Difficulty.medium: 35,
    Difficulty.hard: 28,
  };

  static const int _maxPuzzleRetries = 20;
  int _currentRetryCount = 0;

  // ==================== متدهای ایستا ====================
  // (برچسب‌ها و ناوبری حالت‌ها؛ توسط ویجت‌ها و تست‌ها صدا زده می‌شوند)

  static String gameModeLabel(GameMode mode) => switch (mode) {
    GameMode.classic => 'کلاسیک',
    GameMode.timed => 'زمان‌دار (۵ دقیقه)',
    GameMode.noHints => 'بدون راهنما',
    GameMode.daily => 'چالش روزانه',
    GameMode.record => 'رقابت رکوردی',
  };

  static String gameModeDescription(GameMode mode) => switch (mode) {
    GameMode.classic => 'بدون محدودیت؛ برای تمرین و حل آسوده',
    GameMode.timed => 'پازل را در ۵ دقیقه کامل کنید',
    GameMode.noHints => 'بدون راهنما و بدون فیلتر کاندیداها',
    GameMode.daily => 'یک پازل ثابت در روز؛ فقط یک تلاش',
    GameMode.record => 'رقابت با بهترین زمان؛ حداکثر ۳ خطا',
  };

  static IconData gameModeIcon(GameMode mode) => switch (mode) {
    GameMode.classic => Icons.gamepad_outlined,
    GameMode.timed => Icons.timer_outlined,
    GameMode.noHints => Icons.lightbulb_outline,
    GameMode.daily => Icons.calendar_today_outlined,
    GameMode.record => Icons.emoji_events_outlined,
  };

  static Color gameModeColor(GameMode mode) => switch (mode) {
    GameMode.classic => Colors.blue,
    GameMode.timed => Colors.deepOrange,
    GameMode.noHints => Colors.purple,
    GameMode.daily => Colors.teal,
    GameMode.record => Colors.amber,
  };

  static int nextDailyStreak({
    required String todayKey,
    required String yesterdayKey,
    required String? lastCompletedKey,
    required int currentStreak,
  }) {
    if (lastCompletedKey == todayKey) return currentStreak;
    if (lastCompletedKey == yesterdayKey) return currentStreak + 1;
    return 1;
  }

  static int boxIndex(int row, int col) => (row ~/ 3) * 3 + (col ~/ 3);

  // ==================== مقداردهی اولیه ====================

  @override
  void onInit() {
    super.onInit();
    _initCells();
    ever(difficulty, (_) {
      if (!_isRestoring) unawaited(newGame());
    });
  }

  @override
  void onClose() {
    _timer.dispose();
    _requestSave();
    super.onClose();
  }

  void _initCells() {
    cells = RxList.generate(9, (_) => List.generate(9, (_) => CellData()).obs);
  }
}
