part of '../home_controller.dart';

/// جریان بازی: راهنما، ساخت پازل جدید، تکمیل بازی و شمارش مصرف اعداد.
extension HomeControllerGameFlow on HomeController {
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
    remainingSeconds.value = HomeController.timedGameSeconds;
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
      final clues = HomeController.cluesCount[_effectiveDifficulty]!;

      List<List<int>>? generatedPuzzle;
      bool isUnique = false;

      while (!isUnique && _currentRetryCount < HomeController._maxPuzzleRetries) {
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
}
