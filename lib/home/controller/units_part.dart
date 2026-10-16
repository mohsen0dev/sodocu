part of '../home_controller.dart';

/// واحدهای تکمیل‌شده (ردیف/ستون/بلوک): جشن اعداد ۹تایی و رنگ‌های پس‌زمینه.
extension HomeControllerUnits on HomeController {
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

  bool isCellCelebrating(int row, int col) {
    return celebratingUnits.contains('row-$row') ||
        celebratingUnits.contains('col-$col') ||
        celebratingUnits.contains('box-${HomeController.boxIndex(row, col)}');
  }

  Color? getCompletedUnitBackground(int row, int col) {
    final done =
        _completedRows.contains(row) ||
        _completedCols.contains(col) ||
        _completedBoxes.contains(HomeController.boxIndex(row, col));
    if (!done) return null;
    return Colors.teal.withValues(alpha: 0.18);
  }

  Color getCompletedUnitPeakBackground(int row, int col) {
    final done =
        _completedRows.contains(row) ||
        _completedCols.contains(col) ||
        _completedBoxes.contains(HomeController.boxIndex(row, col));
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

    final box = HomeController.boxIndex(row, col);
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
}
