part of '../home_controller.dart';

/// یادداشت‌های کاندیدا: افزودن/حذف، بررسی اعتبار و پاک‌سازی.
extension HomeControllerNotes on HomeController {
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
}
