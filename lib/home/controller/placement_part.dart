part of '../home_controller.dart';

/// جاگذاری و پاک‌سازی اعداد در خانه‌ها + اعتبارسنجی اعداد مجاز.
extension HomeControllerPlacement on HomeController {
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
}
