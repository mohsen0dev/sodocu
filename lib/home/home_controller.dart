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

  // ==================== مقداردهی اولیه ====================

  @override
  void onInit() {
    super.onInit();
    _initCells();
    ever(difficulty, (_) {
      if (!_isRestoring) unawaited(newGame());
    });
  }

  /// داده‌های ذخیره‌شده را بارگذاری می‌کند و در صورت وجود، بازی قبلی را برمی‌گرداند.
  Future<bool> initialize() async {
    try {
      // در صورت در دسترس نبودن سرویس ذخیره‌سازی، بازی نباید در حالت بارگذاری بماند.
      final prefs = await GamePersistence.tryGetInstance();
      if (prefs != null) {
        _persistence = GamePersistence(prefs);
      } else {
        // دستگاه کند: در پس‌زمینه دوباره تلاش می‌کنیم
        _persistence = GamePersistence(null);
        unawaited(_retryPersistenceInit());
      }
      _loadBestTimes();
      _loadStats();
      final savedGame = _persistence!.loadSavedGame();
      if (savedGame != null && _restoreSavedGame(savedGame) && !isSolved()) {
        _startTimer();
        isLoading.value = false;
        return true;
      }
      _deleteSavedGame();
    } catch (_) {
      // خرابی داده ذخیره‌شده نباید مانع شروع یک بازی جدید شود.
      await _persistence?.remove(GamePersistence.savedGameKey);
    }

    await newGame();
    return false;
  }

  /// تلاش مجدد برای دریافت SharedPreferences در پس‌زمینه.
  Future<void> _retryPersistenceInit() async {
    final prefs = await GamePersistence.tryGetInstance();
    if (prefs != null) _persistence?.updatePrefs(prefs);
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

  // ─────────────────────── بارگذاری/ذخیره بهترین زمان‌ها ───────────────────────

  void _loadBestTimes() {
    final raw = _persistence?.loadBestTimesRaw();
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        bestTimes.assignAll({
          for (final entry in decoded.entries)
            if (entry.key is String && entry.value is num)
              entry.key as String: (entry.value as num).toInt(),
        });
      }
    } catch (_) {
      bestTimes.clear();
    }
  }

  Future<void> _persistBestTimes() async {
    await _persistence?.saveBestTimes(bestTimes);
  }

  // ─────────────────────── بارگذاری/ذخیره آمار ───────────────────────

  int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  void _loadStats() {
    final raw = _persistence?.loadStatsRaw();
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      gamesCompleted.value = (_asInt(decoded['gamesCompleted']) ?? 0).clamp(
        0,
        1 << 30,
      );
      totalCompletedSeconds.value =
          (_asInt(decoded['totalCompletedSeconds']) ?? 0).clamp(0, 1 << 30);
      bestStreak.value =
          (_asInt(decoded['bestStreak']) ?? 0).clamp(0, 1 << 20);
      _currentStreak = (_asInt(decoded['currentStreak']) ?? 0).clamp(
        0,
        1 << 20,
      );
      final last = decoded['lastDailyCompletedKey'];
      _lastDailyCompletedKey = last is String ? last : null;
    } catch (_) {
      gamesCompleted.value = 0;
      totalCompletedSeconds.value = 0;
      bestStreak.value = 0;
      _currentStreak = 0;
      _lastDailyCompletedKey = null;
    }
  }

  Future<void> _persistStats() async {
    await _persistence?.saveStats({
      'gamesCompleted': gamesCompleted.value,
      'totalCompletedSeconds': totalCompletedSeconds.value,
      'bestStreak': bestStreak.value,
      'currentStreak': _currentStreak,
      'lastDailyCompletedKey': _lastDailyCompletedKey,
    });
  }

  // ─────────────────────── بازیابی بازی ذخیره‌شده ───────────────────────

  List<List<int>>? _parseBoard(dynamic raw) {
    if (raw is! List || raw.length != 9) return null;
    final board = <List<int>>[];
    for (final rawRow in raw) {
      if (rawRow is! List || rawRow.length != 9) return null;
      final row = <int>[];
      for (final value in rawRow) {
        if (value is! num || value.toInt() < 0 || value.toInt() > 9) {
          return null;
        }
        row.add(value.toInt());
      }
      board.add(row);
    }
    return board;
  }

  bool _restoreSavedGame(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;

      final savedPuzzle = _parseBoard(decoded['puzzle']);
      final savedSolution = _parseBoard(decoded['solution']);
      final savedCells = decoded['cells'];
      if (savedPuzzle == null ||
          savedSolution == null ||
          savedCells is! List ||
          savedCells.length != 9) {
        return false;
      }

      final difficultyName = decoded['difficulty'];
      final savedDifficulty = Difficulty.values.firstWhere(
        (item) => item.name == difficultyName,
        orElse: () => Difficulty.easy,
      );
      final restoredCells = <List<CellData>>[];
      for (final rawRow in savedCells) {
        if (rawRow is! List || rawRow.length != 9) return false;
        final row = <CellData>[];
        for (final rawCell in rawRow) {
          if (rawCell is! Map ||
              rawCell['value'] is! num ||
              rawCell['notes'] is! List) {
            return false;
          }
          final value = (rawCell['value'] as num).toInt();
          if (value < 0 || value > 9) return false;
          final notes = <int>{};
          for (final note in rawCell['notes']) {
            if (note is! num || note.toInt() < 1 || note.toInt() > 9) {
              return false;
            }
            notes.add(note.toInt());
          }
          row.add(
            CellData(
              value: value,
              isFixed: rawCell['isFixed'] == true,
              notes: notes,
            ),
          );
        }
        restoredCells.add(row);
      }

      _isRestoring = true;
      difficulty.value = savedDifficulty;
      _isRestoring = false;
      puzzle = savedPuzzle;
      _solution = savedSolution;
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          cells[row][col].value = restoredCells[row][col].value;
          cells[row][col].notes = restoredCells[row][col].notes;
          cells[row][col].isFixed = savedPuzzle[row][col] != 0;
        }
      }

      final savedMode = decoded['gameMode'];
      final restoredMode = GameMode.values.firstWhere(
        (item) => item.name == savedMode,
        orElse: () => GameMode.classic,
      );
      // چالش روزانه فقط در همان روز معتبر است؛ بازی ذخیره‌شدهٔ روزهای قبل منقضی می‌شود.
      if (restoredMode == GameMode.daily && decoded['dailyKey'] != _todayKey) {
        return false;
      }
      gameMode.value = restoredMode;
      isGameOver.value = decoded['isGameOver'] == true;
      final savedElapsed = decoded['elapsedSeconds'];
      final savedAt = decoded['savedAt'];
      var totalElapsed = savedElapsed is num ? savedElapsed.toInt() : 0;
      if (savedAt is num) {
        final elapsedWhileClosed =
            (DateTime.now().millisecondsSinceEpoch - savedAt.toInt()) ~/ 1000;
        totalElapsed += elapsedWhileClosed.clamp(0, 31536000);
      }
      elapsedSeconds.value = totalElapsed.clamp(0, 31536000);
      remainingSeconds.value = restoredMode == GameMode.timed
          ? (timedGameSeconds - elapsedSeconds.value).clamp(0, timedGameSeconds)
          : timedGameSeconds;
      final helperUses = decoded['currentHelperUses'];
      currentHelperUses.value = helperUses is num
          ? helperUses.toInt().clamp(0, maxHelperUses)
          : 0;
      final savedMistakes = decoded['mistakes'];
      mistakes.value = savedMistakes is num
          ? savedMistakes.toInt().clamp(0, maxMistakes)
          : 0;
      selectedNumber.value = 0;
      _undoStack.clear();
      _redoStack.clear();
      _updateHistoryButtons();
      recalculateNumberUsage();
      _syncCompletedUnits();
      _hasActiveGame = true;
      return true;
    } catch (_) {
      _isRestoring = false;
      return false;
    }
  }

  // ─────────────────────── تایمر ───────────────────────

  void _startTimer() {
    _timer.start(
      interval: const Duration(seconds: 1),
      onTick: _onTimerTick,
    );
  }

  void _onTimerTick() {
    if (!_hasActiveGame || isLoading.value || isGameOver.value) return;
    elapsedSeconds.value++;
    if (gameMode.value == GameMode.timed) {
      remainingSeconds.value = (timedGameSeconds - elapsedSeconds.value)
          .clamp(0, timedGameSeconds);
      if (remainingSeconds.value == 0) _finishTimedGame();
    }
    if (elapsedSeconds.value % 5 == 0) _requestSave();
  }

  // ─────────────────────── ذخیره‌سازی ───────────────────────

  void _requestSave() {
    if (!_hasActiveGame || _persistence == null) return;
    if (_isSaving) {
      _saveQueued = true;
      return;
    }
    unawaited(_persistActiveGame(_gameSession));
  }

  Future<void> _persistActiveGame(int session) async {
    if (!_hasActiveGame || _persistence == null || session != _gameSession) {
      return;
    }
    _isSaving = true;
    do {
      _saveQueued = false;
      if (!_hasActiveGame || session != _gameSession) break;
      final data = {
        'difficulty': difficulty.value.name,
        'gameMode': gameMode.value.name,
        'isGameOver': isGameOver.value,
        'puzzle': puzzle,
        'solution': _solution,
        'cells': [
          for (final row in cells)
            [
              for (final cell in row)
                {
                  'value': cell.value,
                  'notes': cell.notes.toList(),
                  'isFixed': cell.isFixed,
                },
            ],
        ],
        'currentHelperUses': currentHelperUses.value,
        'mistakes': mistakes.value,
        'elapsedSeconds': elapsedSeconds.value,
        'dailyKey': _todayKey,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _persistence!.saveGame(jsonEncode(data));
    } while (_saveQueued && _hasActiveGame && session == _gameSession);
    _isSaving = false;
    if (_saveQueued && _hasActiveGame) {
      _saveQueued = false;
      _requestSave();
    }
  }

  void _deleteSavedGame() {
    _gameSession++;
    _saveQueued = false;
    _hasActiveGame = false;
    _timer.stop();
    unawaited(_persistence?.deleteGame());
  }

  // ─────────────────────── حالت‌ها و پیکربندی ───────────────────────

  /// راهنما در حالت «بدون راهنما» و «رقابت رکوردی» غیرفعال است
  /// تا رقابت رکوردی بدون هیچ کمکی قابل اعتماد بماند.
  bool get hintsEnabled =>
      gameMode.value != GameMode.noHints && gameMode.value != GameMode.record;
  bool get isDailyMode => gameMode.value == GameMode.daily;
  bool get isRecordMode => gameMode.value == GameMode.record;

  /// آیا خانهٔ [row],[col] همان خانهٔ آخرین خطای رکوردی است؟
  bool isMistakeCell(int row, int col) =>
      _mistakeRow == row && _mistakeCol == col;

  /// آیا پیکر عدد فقط کاندیداهای معتبر را فعال نشان می‌دهد؟
  bool get filterPickerCandidates =>
      gameMode.value != GameMode.record && gameMode.value != GameMode.noHints;

  /// آیا عدد [number] در پیکر خانهٔ [row],[col] قابل انتخاب است؟
  bool isPickerNumberEnabled(int row, int col, int number) {
    final cell = cells[row][col];
    if (cell.value != 0) return false;
    if (!filterPickerCandidates) return true;
    if (noteMode.value && cell.notes.contains(number)) return true;
    return allowedNumbers(row, col).contains(number);
  }

  /// سطح مؤثر: چالش روزانه همیشه از سطح ثابت استفاده می‌کند.
  Difficulty get _effectiveDifficulty =>
      isDailyMode ? dailyDifficulty : difficulty.value;

  /// دانهٔ تصادفی بر اساس تاریخ جلالی
  int get _dailySeed {
    final j = jalaliFromGregorian(DateTime.now());
    return j.year * 10000 + j.month * 100 + j.day;
  }

  /// کلید رکورد بر اساس حالت و سطح مؤثر
  String get recordKey =>
      '${gameMode.value.name}.${_effectiveDifficulty.name}';

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

  String get modeTitle => gameModeLabel(gameMode.value);

  String get dailyDateLabel => formatJalaliFull(DateTime.now());

  bool get dailyAttemptUsed =>
      _persistence?.loadDailyAttempt() == _todayKey;
  String get _todayKey => jalaliDateKey(DateTime.now());

  bool get onboardingSeen => _persistence?.isOnboardingSeen() ?? false;

  Future<void> markOnboardingSeen() async {
    await _persistence?.setOnboardingSeen();
  }

  Future<void> changeMode(GameMode mode) async {
    if (mode == gameMode.value) return;
    if (mode == GameMode.daily && dailyAttemptUsed) {
      showError('تلاش امروز قبلاً انجام شده است.');
      return;
    }
    gameMode.value = mode;
    await newGame();
  }

  // ─────────────────────── پایان بازی ───────────────────────

  void _finishTimedGame() {
    if (isGameOver.value) return;
    isGameOver.value = true;
    _hasActiveGame = false;
    _timer.stop();
    _deleteSavedGame();
    unawaited(HapticFeedback.heavyImpact());
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'زمان تمام شد!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'متأسفانه نتوانستید پازل را در ۵ دقیقه کامل کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('بستن'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      newGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('بازی جدید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _handleRecordMistake(int row, int col, int number) {
    if (!isRecordMode) return;
    if (_solution == null || number == _solution![row][col]) return;
    mistakes.value++;
    _mistakeRow = row;
    _mistakeCol = col;
    mistakeFlashToken.value++;
    unawaited(HapticFeedback.mediumImpact());
    if (mistakes.value >= maxMistakes) {
      _finishRecordGameByMistakes();
    }
  }

  void _finishRecordGameByMistakes() {
    if (isGameOver.value) return;
    isGameOver.value = true;
    _hasActiveGame = false;
    _timer.stop();
    _deleteSavedGame();
    unawaited(HapticFeedback.heavyImpact());
    _showMistakeGameOverDialog();
  }

  void _showMistakeGameOverDialog() {
    if (Get.testMode) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'باخت!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'با $maxMistakes اشتباه بازی را باختید.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'در رقابت رکوردی فقط $maxMistakes خطا مجاز است؛ '
                'برای ثبت بهترین زمان باید پیش از خطای سوم پازل را کامل کنید.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('بستن'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      newGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('تلاش دوباره'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ─────────────────────── توقف بازی ───────────────────────

  void stopGameTimer() {
    _timer.stop();
    _requestSave();
  }

  // ─────────────────────── بهترین زمان‌ها ───────────────────────

  bool _isNewRecord(int seconds) {
    final previous = bestTimes[recordKey];
    return previous == null || seconds < previous;
  }

  Future<void> _saveBestTime() async {
    final current = elapsedSeconds.value;
    if (!_isNewRecord(current)) return;
    bestTimes[recordKey] = current;
    bestTimes.refresh();
    await _persistBestTimes();
  }

  int? bestTimeFor(GameMode mode, Difficulty diff) {
    return bestTimes['${mode.name}.${diff.name}'];
  }

  Future<void> clearBestTime(GameMode mode, Difficulty diff) async {
    final key = '${mode.name}.${diff.name}';
    if (!bestTimes.containsKey(key)) return;
    bestTimes.remove(key);
    bestTimes.refresh();
    await _persistBestTimes();
  }

  Future<void> clearAllBestTimes() async {
    if (bestTimes.isEmpty) return;
    bestTimes.clear();
    bestTimes.refresh();
    await _persistBestTimes();
  }

  // ==================== آمار بازی‌ها ====================

  void _recordGameCompletion() {
    gamesCompleted.value++;
    totalCompletedSeconds.value += elapsedSeconds.value;
    if (isDailyMode) _recordDailyCompletion();
    unawaited(_persistStats());
  }

  void _recordDailyCompletion() {
    final today = _todayKey;
    final yesterday = jalaliDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    _currentStreak = nextDailyStreak(
      todayKey: today,
      yesterdayKey: yesterday,
      lastCompletedKey: _lastDailyCompletedKey,
      currentStreak: _currentStreak,
    );
    _lastDailyCompletedKey = today;
    if (_currentStreak > bestStreak.value) bestStreak.value = _currentStreak;
  }

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

  int? get averageCompletedSeconds => gamesCompleted.value == 0
      ? null
      : totalCompletedSeconds.value ~/ gamesCompleted.value;

  int? get overallBestTime {
    int? best;
    for (final value in bestTimes.values) {
      if (best == null || value < best) best = value;
    }
    return best;
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  // ==================== توابع کمکی Undo/Redo ====================

  List<List<CellData>> _copyCells() {
    return List.generate(9, (i) => List.generate(9, (j) => cells[i][j].copy()));
  }

  void _restoreCells(List<List<CellData>> newCells) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        cells[i][j].value = newCells[i][j].value;
        cells[i][j].isFixed = newCells[i][j].isFixed;
        cells[i][j].notes = Set.from(newCells[i][j].notes);
      }
    }
    cells.refresh();
  }

  void _saveToHistory() {
    _saveSnapshotToHistory(_copyCells());
  }

  void _saveSnapshotToHistory(List<List<CellData>> snapshot) {
    _undoStack.add(snapshot);
    _redoStack.clear();
    _updateHistoryButtons();
  }

  void _updateHistoryButtons() {
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = _redoStack.isNotEmpty;
  }

  void undo() {
    if (isGameOver.value) return;
    if (_undoStack.isEmpty) return;
    _redoStack.add(_copyCells());
    _restoreCells(_undoStack.removeLast());
    _updateHistoryButtons();
    recalculateNumberUsage();
    _syncCompletedUnits();
    celebratingUnits.clear();
    _requestSave();
    _showMessage('مرحله قبل بازگردانی شد', Colors.orange);
  }

  void redo() {
    if (isGameOver.value) return;
    if (_redoStack.isEmpty) return;
    _undoStack.add(_copyCells());
    _restoreCells(_redoStack.removeLast());
    _updateHistoryButtons();
    recalculateNumberUsage();
    _syncCompletedUnits();
    celebratingUnits.clear();
    _requestSave();
    _showMessage('مرحله بعد بازیابی شد', Colors.orange);
  }

  // ==================== توابع اصلی بازی ====================

  void setNumber(int num) {
    selectedNumber.value = num;
    selectedNumber.refresh();
    if (num == 0) {
      _showMessage('حالت حذف فعال شد', Colors.red, duration: 1);
    } else {
      _showMessage('عدد $num انتخاب شد', Colors.blue, duration: 1);
    }
  }

  void toggleNoteMode() {
    noteMode.value = !noteMode.value;
    _showMessage(
      noteMode.value ? 'حالت یادداشت فعال شد' : 'حالت عادی فعال شد',
      Colors.blue,
      duration: 1,
    );
  }

  void selectCell(int r, int c) {
    selectedRow = r;
    selectedCol = c;
    update();
  }

  void placeMainNumber(int r, int c, int number) {
    if (isGameOver.value) return;
    if (cells[r][c].isFixed) {
      showError('این خانه قابل تغییر نیست!');
      return;
    }
    if (number < 1 || number > 9) return;

    final previousValue = cells[r][c].value;
    if (previousValue == number) return;
    if (!SudokuGenerator.canPlace(_currentBoard(), r, c, number)) {
      showError('عدد $number در این خانه قابل قرار نیست!');
      return;
    }
    _updateProgress();

    _saveToHistory();
    if (previousValue != 0) {
      numberUsage[previousValue] = (numberUsage[previousValue]! - 1).clamp(
        0,
        9,
      );
    }
    cells[r][c].value = number;
    cells[r][c].notes.clear();
    numberUsage[number] = numberUsage[number]! + 1;
    _removeNumberFromRelatedNotes(r, c, number);
    removeInvalidNotes();
    numberUsage.refresh();
    cells.refresh();
    _requestSave();
    _afterNumberPlaced(r, c, number);
    _handleRecordMistake(r, c, number);

    if (isSolved()) {
      _completeGame();
    }
    _updateProgress();
  }

  void toggleNote(int r, int c, int number) {
    if (isGameOver.value) return;
    if (cells[r][c].isFixed) return;
    if (cells[r][c].value != 0) {
      showError('ابتدا عدد اصلی خانه را پاک کنید.');
      return;
    }
    if (number < 1 || number > 9) return;

    final hasNote = cells[r][c].notes.contains(number);
    if (!hasNote && !SudokuGenerator.canPlace(_currentBoard(), r, c, number)) {
      showError('عدد $number کاندیدای معتبری برای این خانه نیست.');
      return;
    }

    _saveToHistory();
    if (hasNote) {
      cells[r][c].notes.remove(number);
    } else {
      cells[r][c].notes.add(number);
    }
    cells.refresh();
    _requestSave();
  }

  void setCellNote(int row, int col) {
    final number = selectedNumber.value;
    if (number == 0) {
      showError('برای یادداشت، ابتدا یک عدد از ۱ تا ۹ انتخاب کنید.');
      return;
    }
    toggleNote(row, col, number);
  }

  void clearNotes(int row, int col) {
    if (cells[row][col].notes.isEmpty) return;

    _saveToHistory();
    cells[row][col].notes.clear();
    cells.refresh();
    _requestSave();
  }

  int removeInvalidNotes() {
    var removedCount = 0;
    final board = _currentBoard();

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = cells[row][col];
        if (cell.notes.isEmpty) continue;

        if (cell.isFixed || cell.value != 0) {
          removedCount += cell.notes.length;
          cell.notes.clear();
          continue;
        }

        cell.notes.removeWhere((number) {
          final isValid = SudokuGenerator.canPlace(board, row, col, number);
          if (!isValid) removedCount++;
          return !isValid;
        });
      }
    }

    if (removedCount > 0) cells.refresh();
    return removedCount;
  }

  int invalidNotesCount() {
    var invalidCount = 0;
    final board = _currentBoard();

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = cells[row][col];
        if (cell.notes.isEmpty) continue;

        if (cell.isFixed || cell.value != 0) {
          invalidCount += cell.notes.length;
          continue;
        }

        for (final number in cell.notes) {
          if (!SudokuGenerator.canPlace(board, row, col, number)) {
            invalidCount++;
          }
        }
      }
    }

    return invalidCount;
  }

  void cleanInvalidNotes() {
    final before = _copyCells();
    final removedCount = removeInvalidNotes();
    if (removedCount > 0) {
      _saveSnapshotToHistory(before);
      _requestSave();
    }
    _showMessage(
      removedCount == 0
          ? 'یادداشت نامعتبری پیدا نشد.'
          : '$removedCount یادداشت نامعتبر پاک شد.',
      removedCount == 0 ? Colors.blue : Colors.green,
    );
  }

  void _removeNumberFromRelatedNotes(int row, int col, int number) {
    for (int c = 0; c < 9; c++) {
      if (c != col) cells[row][c].notes.remove(number);
    }
    for (int r = 0; r < 9; r++) {
      if (r != row) cells[r][col].notes.remove(number);
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (r != row || c != col) cells[r][c].notes.remove(number);
      }
    }
  }

  void setCellValue(int row, int col) {
    if (isGameOver.value) return;
    if (!isShow.value) return;

    final newNumber = selectedNumber.value;
    final prevValue = cells[row][col].value;

    // حالت حذف (عدد 0 انتخاب شده)
    if (newNumber == 0) {
      if (prevValue != 0 && !cells[row][col].isFixed) {
        _saveToHistory();
        numberUsage[prevValue] = (numberUsage[prevValue]! - 1).clamp(0, 9);
        cells[row][col].value = 0;
        cells[row][col].notes.clear();
        numberUsage.refresh();
        cells.refresh();
        _syncCompletedUnits();
        removeInvalidNotes();
        _requestSave();
        _showMessage('عدد حذف شد', Colors.red, duration: 1);
        _updateProgress();
      }
      return;
    }

    if (prevValue != 0) {
      numberUsage[prevValue] = (numberUsage[prevValue]! - 1).clamp(0, 9);
    }

    // اگر همان عدد دوباره انتخاب شد ⇒ حذف عدد
    if (prevValue == newNumber) {
      _saveToHistory();
      cells[row][col].value = 0;
      cells[row][col].notes.clear();
      numberUsage.refresh();
      cells.refresh();
      _syncCompletedUnits();
      removeInvalidNotes();
      _requestSave();
      _updateProgress();
      return;
    }

    if (!SudokuGenerator.canPlace(_currentBoard(), row, col, newNumber)) {
      showError('عدد $newNumber در این خانه قابل قرار نیست!');
      if (prevValue != 0) {
        numberUsage[prevValue] = (numberUsage[prevValue]! + 1).clamp(0, 9);
      }
      return;
    }

    if (numberUsage[newNumber]! >= 9) {
      showError('عدد $newNumber قبلاً ۹ بار استفاده شده!');
      if (prevValue != 0) {
        numberUsage[prevValue] = (numberUsage[prevValue]! + 1).clamp(0, 9);
      }
      return;
    }

    _saveToHistory();
    cells[row][col].value = newNumber;
    cells[row][col].notes.clear();
    numberUsage[newNumber] = numberUsage[newNumber]! + 1;
    _removeNumberFromRelatedNotes(row, col, newNumber);
    removeInvalidNotes();
    numberUsage.refresh();
    cells.refresh();
    _requestSave();
    _afterNumberPlaced(row, col, newNumber);
    _handleRecordMistake(row, col, newNumber);

    if (isSolved()) {
      _completeGame();
    }
    _updateProgress();
  }

  void clearCell(int row, int col) {
    if (isGameOver.value) return;
    if (cells[row][col].isFixed) {
      showError('این خانه قابل تغییر نیست!');
      return;
    }

    final prevValue = cells[row][col].value;
    if (prevValue != 0) {
      _saveToHistory();
      numberUsage[prevValue] = (numberUsage[prevValue]! - 1).clamp(0, 9);
      cells[row][col].value = 0;
      cells[row][col].notes.clear();
      numberUsage.refresh();
      cells.refresh();
      _syncCompletedUnits();
      removeInvalidNotes();
      _requestSave();
      _showMessage('عدد حذف شد', Colors.red, duration: 1);
      _updateProgress();
    }
  }

  // ==================== توابع بررسی اعتبار ====================

  bool isCorrect(int row, int col, int value) {
    if (_solution == null) return false;
    return SudokuGenerator.isCorrect(_solution!, row, col, value);
  }

  List<List<int>> _currentBoard() {
    return SudokuGenerator.currentBoard(cells);
  }

  List<int> allowedNumbers(int row, int col) {
    if (_solution == null) return [];
    return SudokuGenerator.allowedNumbers(cells, _solution!, row, col);
  }

  // ==================== راهنما ====================

  void useHelper() {
    if (isGameOver.value) return;
    if (!hintsEnabled) {
      showError('راهنما در این حالت غیرفعال است.');
      return;
    }
    if (currentHelperUses.value >= maxHelperUses || _solution == null) {
      if (currentHelperUses.value >= maxHelperUses) {
        showError('دیگر امکان استفاده از راهنما وجود ندارد.');
      }
      return;
    }

    List<MapEntry<int, int>> emptyCells = [];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value == 0 && !cells[r][c].isFixed) {
          emptyCells.add(MapEntry(r, c));
        }
      }
    }

    if (emptyCells.isEmpty) {
      showError('هیچ خانه خالی برای پر کردن وجود ندارد!');
      return;
    }

    emptyCells.shuffle();
    final row = emptyCells.first.key;
    final col = emptyCells.first.value;
    final correctNumber = _solution![row][col];

    _saveToHistory();
    cells[row][col].value = correctNumber;
    cells[row][col].notes.clear();
    numberUsage[correctNumber] = (numberUsage[correctNumber] ?? 0) + 1;
    _removeNumberFromRelatedNotes(row, col, correctNumber);
    removeInvalidNotes();

    currentHelperUses.value++;
    cells.refresh();
    numberUsage.refresh();
    _requestSave();
    _afterNumberPlaced(row, col, correctNumber);

    _showMessage('راهنما: خانه با عدد $correctNumber پر شد', Colors.blue);

    if (isSolved()) {
      _completeGame();
    }
  }

  // ==================== ساخت پازل ====================

  Future<void> newGame() async {
    if (isLoading.value && _hasActiveGame) return;

    isLoading.value = true;
    _gameSession++;
    _hasActiveGame = false;
    _timer.stop();
    elapsedSeconds.value = 0;
    remainingSeconds.value = timedGameSeconds;
    isGameOver.value = false;
    if (gameMode.value == GameMode.daily) {
      await _persistence?.saveDailyAttempt(_todayKey);
    }
    unawaited(_persistence?.deleteGame());
    _currentRetryCount = 0;

    try {
      await Future.delayed(Duration.zero);

      final random = isDailyMode ? Random(_dailySeed) : null;
      _solution = SudokuGenerator.generateSolvedBoard(random: random);
      final clues = cluesCount[_effectiveDifficulty]!;

      List<List<int>>? generatedPuzzle;
      bool isUnique = false;

      while (!isUnique && _currentRetryCount < _maxPuzzleRetries) {
        generatedPuzzle = SudokuGenerator.generatePuzzle(
          _solution!,
          clues,
          random: random,
        );
        if (SudokuGenerator.hasUniqueSolution(generatedPuzzle)) {
          isUnique = true;
        } else {
          _currentRetryCount++;
        }
      }
      _updateProgress();

      if (!isUnique) {
        showError('امکان تولید پازل یکتا وجود ندارد');
        isLoading.value = false;
        return;
      }

      puzzle = generatedPuzzle;
      currentHelperUses.value = 0;
      mistakes.value = 0;
      _mistakeRow = -1;
      _mistakeCol = -1;
      selectedNumber.value = 0;
      celebratingNumber.value = null;
      celebratingUnits.clear();
      _completedRows.clear();
      _completedCols.clear();
      _completedBoxes.clear();

      for (var i = 1; i <= 9; i++) {
        numberUsage[i] = 0;
      }

      _undoStack.clear();
      _redoStack.clear();
      _updateHistoryButtons();

      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          final num = puzzle![i][j];
          cells[i][j].value = num;
          cells[i][j].isFixed = num != 0;
          cells[i][j].notes.clear();
          if (num != 0) {
            numberUsage[num] = (numberUsage[num] ?? 0) + 1;
          }
        }
      }

      cells.refresh();
      numberUsage.refresh();
      _syncCompletedUnits();
      _hasActiveGame = true;
      _startTimer();
      _requestSave();
      _showMessage('بازی جدید شروع شد!', Colors.green);
      _updateProgress();
    } catch (e) {
      showError('خطا در شروع بازی: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== توابع کمکی UI ====================

  void _completeGame() {
    if (!_hasActiveGame) return;
    final isNewRecord = _isNewRecord(elapsedSeconds.value);
    unawaited(_saveBestTime());
    _recordGameCompletion();
    _deleteSavedGame();
    unawaited(HapticFeedback.mediumImpact());
    _showSuccessDialog(isNewRecord: isNewRecord);
  }

  bool isSolved() {
    if (_solution == null) return false;
    return SudokuGenerator.isSolved(cells, _solution!);
  }

  void recalculateNumberUsage() {
    for (var i = 1; i <= 9; i++) {
      numberUsage[i] = 0;
    }
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final value = cells[i][j].value;
        if (value != 0 && value >= 1 && value <= 9) {
          numberUsage[value] = (numberUsage[value] ?? 0) + 1;
        }
      }
    }
    numberUsage.refresh();
  }

  bool isInitialCell(int row, int col) {
    return puzzle != null && puzzle![row][col] != 0;
  }

  String getCellValue(int row, int col) {
    final val = cells[row][col].value;
    return val == 0 ? '' : val.toString();
  }

  Color getCellTextColor(int row, int col) {
    final value = cells[row][col].value;
    if (value == 0) {
      return Colors.transparent;
    }
    if (_isNumberFullyPlaced(value)) {
      return Get.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800;
    }
    if (cells[row][col].isFixed) {
      return Colors.grey.shade400;
    }
    if (!isActive.value && !isRecordMode) {
      return Colors.blue;
    }
    return isCorrect(row, col, value) ? Colors.blue : Colors.red;
  }

  bool _isNumberFullyPlaced(int number) => _countNumberOnBoard(number) >= 9;

  int _countNumberOnBoard(int number) {
    int count = 0;
    for (final row in cells) {
      for (final cell in row) {
        if (cell.value == number) count++;
      }
    }
    return count;
  }

  void _onNumberPlaced(int number) {
    if (number < 1 || number > 9) return;
    if (_countNumberOnBoard(number) != 9) return;
    celebratingNumber.value = number;
    Future.delayed(const Duration(milliseconds: 850), () {
      if (celebratingNumber.value == number) {
        celebratingNumber.value = null;
      }
    });
  }

  static int boxIndex(int row, int col) => (row ~/ 3) * 3 + (col ~/ 3);

  bool isCellCelebrating(int row, int col) {
    return celebratingUnits.contains('row-$row') ||
        celebratingUnits.contains('col-$col') ||
        celebratingUnits.contains('box-${boxIndex(row, col)}');
  }

  Color? getCompletedUnitBackground(int row, int col) {
    final done =
        _completedRows.contains(row) ||
        _completedCols.contains(col) ||
        _completedBoxes.contains(boxIndex(row, col));
    if (!done) return null;
    return Colors.teal.withValues(alpha: 0.18);
  }

  Color getCompletedUnitPeakBackground(int row, int col) {
    final done =
        _completedRows.contains(row) ||
        _completedCols.contains(col) ||
        _completedBoxes.contains(boxIndex(row, col));
    if (!done) return Colors.amber.withValues(alpha: 0.3);
    return Colors.teal.withValues(alpha: 0.38);
  }

  bool _isUnitValuesComplete(List<int> values) {
    if (values.length != 9 || values.any((v) => v == 0)) return false;
    return values.toSet().length == 9;
  }

  bool isRowComplete(int row) {
    return _isUnitValuesComplete([
      for (int c = 0; c < 9; c++) cells[row][c].value,
    ]);
  }

  bool isColComplete(int col) {
    return _isUnitValuesComplete([
      for (int r = 0; r < 9; r++) cells[r][col].value,
    ]);
  }

  bool isBoxComplete(int box) {
    final startRow = (box ~/ 3) * 3;
    final startCol = (box % 3) * 3;
    final values = <int>[];
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        values.add(cells[r][c].value);
      }
    }
    return _isUnitValuesComplete(values);
  }

  void _syncCompletedUnits() {
    _completedRows.clear();
    _completedCols.clear();
    _completedBoxes.clear();
    for (int i = 0; i < 9; i++) {
      if (isRowComplete(i)) _completedRows.add(i);
      if (isColComplete(i)) _completedCols.add(i);
      if (isBoxComplete(i)) _completedBoxes.add(i);
    }
    cells.refresh();
  }

  void _afterNumberPlaced(int row, int col, int number) {
    unawaited(HapticFeedback.lightImpact());
    _onNumberPlaced(number);
    _checkAndCelebrateUnits(row, col);
  }

  void _checkAndCelebrateUnits(int row, int col) {
    final newUnits = <String>[];

    if (isRowComplete(row) && _completedRows.add(row)) {
      newUnits.add('row-$row');
    } else if (!isRowComplete(row)) {
      _completedRows.remove(row);
    }

    if (isColComplete(col) && _completedCols.add(col)) {
      newUnits.add('col-$col');
    } else if (!isColComplete(col)) {
      _completedCols.remove(col);
    }

    final box = boxIndex(row, col);
    if (isBoxComplete(box) && _completedBoxes.add(box)) {
      newUnits.add('box-$box');
    } else if (!isBoxComplete(box)) {
      _completedBoxes.remove(box);
    }

    if (newUnits.isEmpty) return;

    celebratingUnits.addAll(newUnits);
    celebrationToken.value++;
    Future.delayed(const Duration(milliseconds: 950), () {
      celebratingUnits.removeAll(newUnits);
      cells.refresh();
    });
  }

  // ==================== Progress Tracking ====================

  void _updateProgress() {
    int completed = 0;
    int empty = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].value != 0) {
          completed++;
        } else {
          empty++;
        }
      }
    }
    completedCells.value = completed;
    emptyCells.value = empty;
  }

  // ==================== پیام‌ها ====================

  void _showMessage(String message, Color color, {int duration = 2}) {
    if (Get.testMode) return;
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color,
        messageText: Text(message, style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: duration),
        margin: const EdgeInsets.all(10),
        borderRadius: 12,
      ),
    );
  }

  void showError(String message) {
    if (Get.testMode) return;
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        messageText: Text(message, style: TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
        borderRadius: 12,
      ),
    );
  }

  void _showSuccessDialog({required bool isNewRecord}) {
    final recordMode = isRecordMode;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                recordMode
                    ? (isNewRecord ? 'رکورد جدید! 🏆' : 'پازل کامل شد!')
                    : 'تبریک! 🎉',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (recordMode) ...[
                Text(
                  'زمان: ${formatDuration(elapsedSeconds.value)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mistakes.value == 0
                      ? 'بدون خطا'
                      : '${mistakes.value} خطا',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'شما بازی را با موفقیت حل کردید!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('بستن'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      newGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('بازی جدید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
