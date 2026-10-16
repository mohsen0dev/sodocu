part of '../home_controller.dart';

/// بارگذاری/ذخیره‌سازی داده‌ها: بهترین زمان‌ها، آمار، بازی ذخیره‌شده
/// و صف ذخیرهٔ بازی فعال.
extension HomeControllerPersistence on HomeController {
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
          ? (HomeController.timedGameSeconds - elapsedSeconds.value)
                .clamp(0, HomeController.timedGameSeconds)
          : HomeController.timedGameSeconds;
      final helperUses = decoded['currentHelperUses'];
      currentHelperUses.value = helperUses is num
          ? helperUses.toInt().clamp(0, maxHelperUses)
          : 0;
      final savedMistakes = decoded['mistakes'];
      mistakes.value = savedMistakes is num
          ? savedMistakes.toInt().clamp(0, HomeController.maxMistakes)
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
}
